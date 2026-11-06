# Tested devices

These profiles describe two individual devices and firmware revisions. They are not a universal cleanup list for every TCL TV or Portronics projector. Long-term reliability across other devices and future firmware is not established.

## Portronics Beem 440

| Item | Tested value |
|---|---|
| Android | 11 / API 30 |
| Firmware display ID | `UI_Veng.projector.20250321.160324` |
| Android model / device | `adt3` / `adt3` |
| Board platform | `ares`, Allwinner `sun50iw12p1` |
| Memory / physical display | 1 GB / 1280 × 720 |
| Original Home | `com.htc.htclauncherhighenglishd08/com.htc.activity.HomeActivity` |
| Native settings | `com.htc.htcsettings/com.htc.activity.HomeActivity` |
| New Home | `com.gathin.tvhome/.MainActivity` |

### Configuration

The dock contains these installed package IDs, in order:

1. `com.google.android.youtube.tv`
2. `com.netflix.mediaclient`
3. `com.amazon.avod.thirdpartyclient`
4. `in.startv.hotstar`

Netflix and Prime on this unit advertise ordinary Android launch activities rather than Leanback activities. Both are included in `library_apps` as well as `dock_apps`; setting the dock order alone does not discover them.

The original HTC Home remains enabled and is hidden from the custom app grid. No accessibility helper or remote-key redirect is enabled. The native projection, HDMI, focus, power, keyboard, Bluetooth and USB input services are retained, as are app stores, casting and update components.

Select the Settings gear to open Android settings. **Hold the physical remote's OK button on the gear**, then choose **Native settings**, to open the original projector controls. An injected long press behaved as a short press on this firmware; the owner verified the real remote gesture.

### Cleanup

The initial list disables only:

- `com.htc.eventuploadservice`: audited event uploader.
- `com.htc.expandsdk`: audited advertising SDK.

`com.hotack.screensaversdk` was disabled separately, only after the replacement Photos screensaver was installed and verified. The original `com.htc.screensaver` package remains enabled for recovery. An already-disabled NFC package was left unchanged and is not a new cleanup target.

### Validation on the original unit

- Release build and lint passed; the configured launcher APK was 586,449 bytes, below upstream's 589,824-byte limit.
- Installed configuration and uploaded wallpaper checksums were read back.
- All four dock entries opened their intended apps using D-pad navigation.
- Home, grid, Inputs, Android settings and native projector settings were checked.
- After a restart during the initial Cinematic setup, the new Home returned as both the default and resumed activity; the initial two cleanup packages remained disabled.
- The owner confirmed the real remote, video playback, Bluetooth speaker sound, volume control and Native settings gesture worked.
- The owner confirmed the later Sunrise theme looked clear and brighter from the viewing position.
- Photos was observed as the bound DreamService and displaying a new photograph. All four uploaded photographs matched their local MD5 values.

The restart check preceded the later Sunrise and Photos changes. Photos playback resource use, MP4 screensaver playback, gaming latency and long-term operation were not benchmarked. Firmware-advertised HDMI entries do not prove that every advertised connector physically exists.

## TCL UnionTV

| Item | Tested value |
|---|---|
| Model / product | UnionTV / TCL-AP-RT41DT-S1 |
| Android | 9 / API 28 |
| Firmware display ID | `PPR2.180905.006.A1 release-keys` |
| TCL software version | `V8-R41KT01-LF1V343` |
| Board platform | Realtek `rtd284x` / RT2841 |
| Original Home | `com.google.android.tvlauncher/.MainActivity` |
| TV input package | `com.tcl.tv` |
| New Home | `com.gathin.tvhome/.MainActivity` |

Its dock uses `com.google.android.youtube.tv`, `com.netflix.ninja`, `com.amazon.amazonvideo.livingroom` and `in.startv.hotstar`. Confirm these IDs against the compiled profile and your installed apps before building.

The original deployment disabled the stock launcher only after the custom Home had started successfully. The public installation wrapper preserves stock Home on both devices; this differs from the original TCL deployment. The eight-package cleanup list covers telemetry, feedback, recommendations, partner widgets and retail-demo content. It retains streaming, Google Assistant, casting, accessibility, updates, USB media, television inputs and audio services.

### Validation on the original unit

- Release build and lint passed; the configured APK was 586,409 bytes.
- Installation and upload checksum checks succeeded.
- All four dock apps opened; protected Netflix output was checked through the resumed activity rather than a screenshot.
- Inputs showed HDMI, AV and Live TV; settings and D-pad navigation were checked.
- After restart, the custom launcher remained default and resumed, and all selected cleanup packages stayed disabled.
- The owner confirmed the physical remote, video playback and HDMI home-theatre sound and volume controls worked.
- Cinematic theme upload and configuration read-back succeeded. The existing Aerial Views system screensaver was retained.

The owner reported turning debugging off and restarting. Subsequent port checks timed out, so independent confirmation of debugging closure was not established. A timeout is not proof that a port is closed.

## Before using either profile

Read the exact model and firmware on your own device, inspect its installed packages and save its original state. Preserve any package whose role is uncertain. Test the real remote, input selection, sound and native settings before considering cleanup complete.

The companion wrapper scripts were subsequently checked locally with parsing and offline validation. They were not rerun end to end on these devices after the original setup sessions ended. Hardware validation above describes the setup performed with the upstream tools.
