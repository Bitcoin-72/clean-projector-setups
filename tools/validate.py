#!/usr/bin/env python3
"""Offline publication checks for the companion repository (standard library only)."""

from __future__ import annotations

import configparser
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {".git", "upstream", ".local-state", "__pycache__"}
PRIVATE_DIRS = {"backup", "checks", "shots", "work", "adbkey", "venv", ".venv", ".gradle", "build"}
PRIVATE_SUFFIXES = {".apk", ".aab", ".pem", ".key", ".keystore", ".jks", ".p12", ".pfx"}
MEDIA_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}
IP_RE = re.compile(r"(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w.])")
MAC_RE = re.compile(r"(?<![\w:])(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}(?![\w:])", re.I)
PERSONAL_PATH_RE = re.compile(r"[a-z]:[\\/]+Users[\\/]+[^\s\\/]+|/(?:Users|home)/[^\s/]+", re.I)
SECRET_RE = re.compile(
    r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
    r"|\bgh[pousr]_[A-Za-z0-9]{20,}\b|\bgithub_pat_[A-Za-z0-9_]{20,}\b"
    r"|\bAKIA[A-Z0-9]{16}\b"
)
INLINE_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(\s*(<[^>\n]+>|[^\s)]+)(?:\s+[\"'][^\n]*?[\"'])?\s*\)")
REFERENCE_LINK_RE = re.compile(r"^\s{0,3}\[[^\]\n]+\]:\s*(<[^>\n]+>|\S+)", re.M)


def public_files() -> list[Path]:
    files = []
    for folder, dirs, names in os.walk(ROOT):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        files.extend(Path(folder) / name for name in sorted(names) if name != ".git")
    return files


def strip_fences(text: str) -> str:
    lines = []
    fence = None
    for line in text.splitlines():
        match = re.match(r"^\s{0,3}(`{3,}|~{3,})", line)
        if match:
            marker = match.group(1)
            if fence is None:
                fence = (marker[0], len(marker))
            elif marker[0] == fence[0] and len(marker) >= fence[1]:
                fence = None
            continue
        if fence is None:
            lines.append(line)
    return "\n".join(lines)


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    files = public_files()
    text_files: dict[Path, str] = {}
    parsed_json: dict[str, object] = {}

    def error(path: Path | str, message: str) -> None:
        label = path.relative_to(ROOT).as_posix() if isinstance(path, Path) else path
        errors.append(f"{label}: {message}")

    for path in files:
        rel = path.relative_to(ROOT)
        lower_parts = {part.lower() for part in rel.parts}
        if lower_parts & PRIVATE_DIRS:
            error(path, "private state or build directory must not be distributed")
        if (path.suffix.lower() in PRIVATE_SUFFIXES or path.name.lower().startswith("adbkey")
                or path.name.lower() == "local.properties"
                or (path.name.startswith(".env") and path.name != ".env.example")):
            error(path, "credential, local configuration, or build artifact must not be distributed")
        if path.is_symlink():
            error(path, "public companion files must not be symlinks")
            continue
        if path.suffix.lower() in MEDIA_SUFFIXES:
            continue
        try:
            content = path.read_text(encoding="utf-8-sig")
            if "\x00" in content:
                raise UnicodeError("NUL byte")
        except (UnicodeError, OSError):
            error(path, "unexpected binary or unreadable text file")
            continue
        text_files[path] = content
        for number, line in enumerate(content.splitlines(), 1):
            if MAC_RE.search(line):
                error(path, f"line {number}: possible device MAC address")
            if PERSONAL_PATH_RE.search(line):
                error(path, f"line {number}: personal absolute filesystem path")
            if SECRET_RE.search(line):
                error(path, f"line {number}: possible credential")
            for match in IP_RE.finditer(line):
                try:
                    address = ipaddress.IPv4Address(match.group())
                except ipaddress.AddressValueError:
                    continue
                if (address.is_private or address.is_link_local) and not address.is_loopback:
                    error(path, f"line {number}: possible private device IP address")
        try:
            if path.suffix.lower() == ".json":
                parsed_json[rel.as_posix()] = json.loads(content)
            elif path.suffix.lower() == ".xml":
                ET.fromstring(content)
        except (ValueError, ET.ParseError) as exc:
            error(path, f"invalid {path.suffix[1:].upper()}: {exc}")

    manifest = parsed_json.get("assets/manifest.json")
    if not isinstance(manifest, dict):
        error("assets/manifest.json", "expected a JSON object mapping media paths to hashes")
    else:
        actual_media = {p.relative_to(ROOT).as_posix() for p in files if p.suffix.lower() in MEDIA_SUFFIXES}
        for name in sorted(actual_media - manifest.keys()):
            error(name, "media file is missing from the hash manifest")
        for name, record in manifest.items():
            asset = (ROOT / name).resolve()
            if not asset.is_relative_to(ROOT) or not asset.is_file():
                error("assets/manifest.json", f"missing or invalid asset path: {name}")
                continue
            if not isinstance(record, dict):
                error(name, "expected bytes and sha256 in the asset manifest")
                continue
            payload = asset.read_bytes()
            if len(payload) != record.get("bytes"):
                error(name, "file length differs from manifest")
            if hashlib.sha256(payload).hexdigest() != record.get("sha256"):
                error(name, "SHA-256 differs from manifest")

    pin = parsed_json.get("UPSTREAM.json")
    if not isinstance(pin, dict) or not re.fullmatch(r"[0-9a-f]{40}", str(pin.get("commit", ""))):
        error("UPSTREAM.json", "expected a complete 40-character commit pin")
    else:
        config = configparser.ConfigParser()
        try:
            config.read(ROOT / ".gitmodules", encoding="utf-8")
            section = config['submodule "upstream"']
            if section.get("path") != "upstream":
                error(".gitmodules", "submodule path must be upstream")
            if section.get("url", "").removesuffix(".git") != pin.get("repository"):
                error(".gitmodules", "URL differs from UPSTREAM.json")
        except (configparser.Error, KeyError) as exc:
            error(".gitmodules", f"invalid upstream submodule declaration: {exc}")
        if shutil.which("git") and (ROOT / ".git").exists():
            result = subprocess.run(["git", "-C", str(ROOT), "ls-files", "--stage", "--", "upstream"],
                                    capture_output=True, text=True, check=False)
            fields = result.stdout.split()
            if result.returncode or len(fields) != 4 or fields[0] != "160000" or fields[1] != pin["commit"]:
                error("upstream", "Git index gitlink differs from UPSTREAM.json (stage the pinned submodule)")
        else:
            warnings.append("Git index check skipped: no local Git repository or Git executable")

    for path, content in text_files.items():
        if path.suffix.lower() != ".md":
            continue
        markdown = strip_fences(content)
        targets = [m.group(1) for m in INLINE_LINK_RE.finditer(markdown)]
        targets += [m.group(1) for m in REFERENCE_LINK_RE.finditer(markdown)]
        for target in targets:
            target = target.strip("<>")
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            if any(marker in target for marker in ("<", ">", "{", "}")):
                continue  # Documented placeholders are not actual file links.
            destination = path.parent / unquote(parsed.path)
            if not destination.exists():
                error(path, f"broken local Markdown link: {target}")

    for required in ("LICENSE", "NOTICE.md", "licenses/cleanyourtv-MIT.txt", "screensaver/CREDITS.md"):
        if not (ROOT / required).is_file():
            error(required, "required licence or attribution file is absent")
    for warning in warnings:
        print(f"WARNING: {warning}")
    for problem in errors:
        print(f"ERROR: {problem}")
    if errors:
        print(f"Validation failed: {len(errors)} issue(s).")
        return 1
    print(f"Validated {len(files)} companion files: formats, asset hashes, upstream pin, privacy patterns and local links.")
    print("No device connections were made. Image contents and free-form identifiers still require human review.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
