# Adapt this setup to another Android projector

You can reuse this workflow, the wallpaper artwork and the photo collection. The supplied Beem 440 scripts deliberately require its exact tested firmware. They do not claim compatibility with every Android projector.

1. Confirm your projector runs Android with API 26 or later and offers owner-enabled debugging. A projector running another operating system needs a different method.
2. Clone this repository with its pinned upstream submodule and give your coding agent [PROMPT.md](../PROMPT.md). Read the upstream procedure before connecting.
3. Read your model, Android version, firmware, installed app packages and original Home. Save packages, disabled states and settings privately before changing anything.
4. Build a fresh launcher configuration using the pinned upstream source. Map your installed streaming apps and native settings; keep the manufacturer’s launcher enabled until Home, projection controls and the physical remote work reliably.
5. Adapt the theme’s dock, library and hidden-app package IDs. The Sunrise artwork can be reused; the Beem’s app IDs and cleanup list must be reviewed for your device.
6. Inspect each proposed cleanup package. Preserve projection/focus/keystone, power, HDMI, input, keyboard, Bluetooth, audio, casting and updates. Disable only understood packages using upstream’s recovery tools; never copy another model’s cleanup list blindly.
7. Test the real remote, video, speakers, settings and restart. Record what was actually verified and close debugging afterward.

For a new model, use the upstream tools directly with your audited configuration. The public wrappers currently accept the Beem profile only. Adding another supported profile requires its metadata, configuration, reviewed cleanup list, firmware guard and offline tests to be updated together.

Keep raw backups, addresses and debugging keys local. [Contribute](../CONTRIBUTING.md) only the reusable configuration, credited assets and sanitized results.
