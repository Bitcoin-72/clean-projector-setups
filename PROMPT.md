# Set up a matching TV or projector with a coding agent

Copy this prompt into your coding agent after cloning the repository with its submodule:

```text
Help me apply this repository's matching device profile to my TV or projector.

Read README.md, docs/SETUP.md, docs/DEVICES.md and docs/RESTORE.md first. Read the
pinned upstream AGENTS.md and PROMPT.md before using its device tools. Keep the
upstream revision pinned. Use the existing launcher and tools; do not create a
different launcher or fetch a prebuilt APK.

Discover the exact model, Android version and firmware build before choosing a
profile. Stop on a mismatch and explain it. The generic model adt3 alone does not
identify a Beem 440. Ask for my device address only if it cannot be found from
information I have already provided. Never publish that address or other device
identifiers.

Confirm which streaming apps, casting, voice, speakers, USB devices, inputs and
updates I use. Keep those features available. Save a private original-state backup
before changes and retain every recovery record. Keep runtime state, ADB keys and
raw diagnostics out of Git.

Build the matching configuration from source, preserve the stock launcher and
apply the matching theme. Ask me to test the physical remote and sound; injected
keys do not establish that every real button or long press works. On the Beem,
verify the real long-OK Settings menu opens Native settings and projection
controls remain accessible.

Review the profile's small cleanup list. Disable only verified packages with the
official recovery tools, never uninstall packages. Do not modify firmware, root
the device, disable core Android services or apply a generic RAM-booster tweak.
Treat optional Photos setup and the old screensaver SDK list as separate steps.

Read back the active settings, test Home and retained features, and verify a
restart. Report what was actually checked and anything not established. Do not
claim an FPS improvement from startup or memory figures.

When finished, help me turn debugging off, revoke authorisations and verify the
actual debugging ports are closed. A timeout is inconclusive. Leave a concise
record of what changed and how to restore my own saved state.
```

The public profiles are examples tested on particular firmware revisions. Follow your own device's recorded state when restoring.
