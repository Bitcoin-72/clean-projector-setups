# Contribute a projector setup

This repository is for Android projectors. The Portronics Beem 440 is the first tested example; additional projector models are welcome.

Open a pull request containing a `profiles/<brand-model>/` folder with model/Android/exact firmware metadata, a launcher configuration and a small reviewed cleanup list. Explain native projection settings, original Home, required hardware services and how your own restore record was captured. State which physical remote, audio, inputs, playback and restart checks passed, and what remains untested.

New wrapper support must include exact identity matching and offline guard tests. Follow [the adaptation guide](docs/OTHER-PROJECTORS.md) and the pinned upstream procedure. Do not publish raw backups, network addresses, serial numbers, account screenshots, keys or prebuilt APKs. Keep photo and wallpaper licences with their assets. Performance claims need measurements and their limits.

Before submitting, run `python tools/validate.py` and `powershell -NoProfile -File scripts/Test-Scripts.ps1` from the repository root. These checks do not connect to a device.
