# Files that stay private

This public repository contains reusable configurations, licensed artwork, reviewed screenshots and a measurement summary. It does not contain the original devices' recovery records or complete diagnostics.

Keep these out of commits, issues and screenshots:

- ADB private keys, authorisation files and signing keys.
- Device serial numbers, MAC addresses, IP addresses and Wi-Fi names.
- Accounts, email addresses, profile names and personal notifications.
- Full `getprop`, settings, package and network diagnostic dumps.
- Recovery files made for your device, including filenames that encode its address.
- Local tool environments, SDKs, Gradle caches and absolute personal filesystem paths.

The device identity needed to assess compatibility is limited to the model, Android version, board platform and firmware build. A generic Android model such as `adt3` is not sufficient by itself.

Make backups before changes and retain them locally. Review the files selected for a commit even when `.gitignore` is present; an ignore rule does not remove an already tracked file or conceal information inside another file.

Debugging is needed only while changing the setup. Turn USB, Network/ADB and Wireless debugging off when finished, revoke debugging authorisations where available, and restart. Use upstream's `tools/adb-closed.py` for the device's actual debugging port. Only an explicit refused connection establishes that the port is closed; an unreachable or sleeping device is inconclusive.
