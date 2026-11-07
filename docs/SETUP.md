# Set up a matching device

These instructions use Windows and PowerShell. The upstream project also documents other operating systems; this companion's wrapper scripts target Windows.

## 1. Get the pinned source

Clone this repository with `--recurse-submodules`. If it is already cloned, run this from the repository root:

```powershell
git submodule update --init --recursive
git -C upstream rev-parse HEAD
```

The second command must show:

```text
1937c8048672d4c322e70fe805bda1175f546716
```

Do not replace this pin with the latest upstream revision during an installation. New upstream versions may change theme keys, recovery handling or launcher behaviour.

## 2. Prepare the computer

You need Git, Python, JDK 17 and Android SDK platform 34 with build-tools 34.0.0. Android Studio can provide the Java and Android tools. Follow the [upstream build prerequisites](https://github.com/Gathin23/cleanyourtv/blob/1937c8048672d4c322e70fe805bda1175f546716/CONTRIBUTING.md).

From the repository root, prepare the local Python environment:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Initialize.ps1
```

This does not install Java or the Android SDK globally. Set `JAVA_HOME` and `ANDROID_HOME` to your existing installations as needed.

The upstream Python tools use a local virtual environment at `upstream/tools/venv`. Build output, downloaded dependencies, debugging keys and local backups are private runtime state and must remain untracked. No SDK, APK or personal key is included here.

To run the local parser and offline wrapper checks without contacting a device:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Scripts.ps1
```

These checks do not replace testing an installation on your actual hardware. The public wrappers were packaged after the original device setup and have not been rerun end to end on the original devices.

## 3. Confirm the device and preserve its original state

1. Compare your device against [DEVICES.md](DEVICES.md), including its exact firmware build.
2. Put the device and computer on the same trusted local network.
3. Enable the device's USB/Network debugging option and accept the authorisation prompt on the device. If your firmware exposes a separate Wireless debugging option, use upstream's documented connection procedure for it.
4. Supply your device address to the wrapper; the examples use `DEVICE_IP` as a placeholder.
5. Save the original packages and disabled list, properties, settings and resolved Home before changing anything. Keep the backup locally.
6. Confirm the expected streaming apps and package IDs exist. App package IDs can differ across projector firmware revisions.

The public profiles match the original units, not every device carrying the same retail name. Stop on an unexpected firmware or package mismatch and inspect it before proceeding.

## 4. Build and apply a theme

The examples below use `DEVICE_IP` as a placeholder. Replace it with your device address. For the Beem:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-and-Install.ps1 -Profile portronics-beem-440 -TvHost DEVICE_IP
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Apply-Theme.ps1 -Profile portronics-beem-440 -TvHost DEVICE_IP -Look Sunrise -FastAnimations
```

The installation wrapper supplies the profile's `launcher-config.xml` to the pinned upstream build and preserves the projector’s stock launcher. Build from source; do not install an APK from an unrelated device. Before its first change, the wrapper saves the device's relevant preferences in the ignored `.local-state` folder. Keep that folder for recovery.

For the Beem, choose `themes/projector-sunrise-fast` for the tested bright interface or `themes/cinematic-projector` for the earlier dark appearance.

The bright theme keeps a static wallpaper, uniform tiles, white labels and reduced motion. Optional Android animation scales of 0.5 are a separate system setting; save their existing values before changing them.

Test Home, all four dock apps, D-pad navigation, the grid, Inputs, settings and sound. On the Beem, also hold the real remote's OK button on the Settings gear and choose Native settings. Confirm the original projection controls open. A simulated key event is not proof that a physical long press works.

## 5. Apply reviewed cleanup separately

Review the device's `debloat.txt`, then apply it separately. For the Beem:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Apply-Cleanup.ps1 -Profile portronics-beem-440 -TvHost DEVICE_IP
```

The wrapper uses upstream's disable and recovery tools, disables rather than uninstalls, and records the prior package states. Keep the resulting local backup and recovery records.

The Beem's optional old screensaver SDK list documents a later change made on the original unit. The base cleanup wrapper does not apply that extra list. Use upstream's documented disable/recovery procedure for it only after installing and verifying Photos; keep its separate recovery record.

Test the physical remote, video, sound, native settings and inputs again, then restart once and verify Home and the retained features return. Leave core Android, firmware updates, keyboard, input, Bluetooth, audio and projection services enabled.

## 6. Optional Photos screensaver on the Beem

Build the pinned upstream Photos add-on and sync the included collection:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install-Photos.ps1 -TvHost DEVICE_IP
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Sync-Photos.ps1 -TvHost DEVICE_IP -Start
```

The sync uses [`screensaver/pictures`](../screensaver/pictures), 30 seconds per photo and a two-minute idle delay. The theme disables the competing Home idle clock.

Selecting a new screensaver may not stop one already running. Wake the device first, then start Photos or wait for it to become idle. Verify that Photos actually displays the new collection, rather than relying only on a saved component name.

The original setup checked all four photographs through the app's file provider because direct shell access to app-owned Android data directories was restricted. A shell listing of zero files did not mean that the photographs were missing.

Keep the [photo credits](../screensaver/CREDITS.md) with the images. See [RESTORE.md](RESTORE.md) before replacing the previous screensaver settings.

## 7. Finish

Confirm Home, the real remote, video, audio, settings and inputs. Turn debugging off, revoke authorisations where available, restart and use upstream's `tools/adb-closed.py` to check the connection. A timeout is inconclusive.

Keep your private backup and recovery record for future maintenance. The launcher and screensaver work without debugging enabled.
