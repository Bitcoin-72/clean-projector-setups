# Restore your previous setup

Recovery must use the state captured from **your device before your changes**. The public repository deliberately does not ship the original owner's backups or recovery commands.

## Keep before starting

Save the current Home component, package enable/disable states, animation scales and screensaver settings. Keep the recovery record produced by upstream's disable tool. Preserve the exact list used with that record; editing a cleanup list can prevent the recovery tool from locating the matching state.

Keep this checkout in the same location, its private `.local-state` folder and the official recovery records under `~/.cleanyourtv`. The wrappers copy the cleanup record into `.local-state` as an additional private backup. Their lookup uses the device address and checkout path; if either changes, preserve the old records and migrate them deliberately before attempting recovery. Do not make a new baseline snapshot from the already modified device and treat it as its original state.

The local wrappers in [`scripts/`](../scripts) are the entry point for this repository. Read their help before running them. Upstream's [restore guide](https://github.com/Gathin23/cleanyourtv/blob/1937c8048672d4c322e70fe805bda1175f546716/docs/restore.md) explains its recovery mechanism.

## Restore cleanup and Home

1. Temporarily enable debugging on the same device and authorise your computer.
2. Use the saved cleanup list and matching upstream recovery record to generate and apply the restore plan.
3. Restore the Home component captured in your backup. Test the real Home button and the manufacturer's settings.
4. Restore your saved animation values if you changed them separately from cleanup.
5. Restore your previous screensaver selection, enabled state and idle timeout if you installed Photos.
6. Turn debugging off and verify closure when finished.

For the base cleanup and the preferences captured by these wrappers, use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore-Cleanup.ps1 -Profile portronics-beem-440 -TvHost DEVICE_IP
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore-Preferences.ps1 -Profile portronics-beem-440 -TvHost DEVICE_IP
```

Use `-Profile tcl-uniontv` for the TCL. Replace `DEVICE_IP` with your device address. `Restore-Cleanup.ps1` requires the matching upstream recovery record. `Restore-Preferences.ps1` restores the Home, animation and screensaver preferences saved before the first wrapper change; keep `.local-state` available.

Upstream `tools/restore.ps1` takes the original list and can restore recorded package states, Home and animation settings. Restoring one cleanup list does not automatically undo a separately applied list or add-on. If you manually applied the optional old screensaver SDK cleanup, restore its separate record as well.

On the tested Beem, the original Home was `com.htc.htclauncherhighenglishd08/com.htc.activity.HomeActivity`; on the tested TCL it was `com.google.android.tvlauncher/.MainActivity`. These are reference values, not replacements for your own backup.

## Restore only the appearance

Applying the matching Cinematic theme changes the look while retaining the custom Home and cleanup. Resetting a theme returns to the launcher's built-in appearance. Neither action by itself re-enables disabled packages, restores a previous Home or resets Android animation scales.

## Restore only the screensaver

Upstream Photos `sync.ps1 -Off` restores its saved previous screensaver component and enabled state and removes its synced pictures. Its saved state does **not** include every system setting. Restore `screen_off_timeout` separately from your backup when it was changed to obtain the two-minute Photos delay.

If you also disabled `com.hotack.screensaversdk`, restore that package from the separate cleanup record before relying on the original screensaver. The original `com.htc.screensaver` package should remain installed and enabled throughout.

## What recovery leaves installed

Returning Home and the screensaver to their previous owners does not require uninstalling the custom launcher or Photos. Disabled packages can be re-enabled. Preserve the backup until you have verified the actual remote, input selection, sound, native settings and restart behaviour.
