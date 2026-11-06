param(
    [Parameter(Mandatory = $true)][ValidateSet('portronics-beem-440', 'tcl-uniontv')][string]$Profile,
    [Parameter(Mandatory = $true)][string]$TvHost
)
. (Join-Path $PSScriptRoot 'Common.ps1')
[void](Assert-Device $Profile $TvHost)
$file = Join-Path (Get-StateDirectory $Profile $TvHost) 'before.json'
if (-not (Test-Path -LiteralPath $file)) { throw 'No original preference snapshot exists for this profile and address.' }
$state = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
if ($state.profile -ne $Profile -or $state.host -ne $TvHost) { throw 'The saved preferences do not belong to this target.' }
if ($state.home -notmatch '^[A-Za-z_][\w.]*/[\w.$]+$') { throw 'The saved Home component is invalid.' }
$allowed = @('global/window_animation_scale', 'global/transition_animation_scale', 'global/animator_duration_scale', 'secure/screensaver_components', 'secure/screensaver_default_component', 'secure/screensaver_enabled', 'system/screen_off_timeout')
# Validate the complete plan before the first write.
foreach ($key in $allowed) {
    if (-not $state.settings.PSObject.Properties[$key]) { throw "Saved preference $key is missing." }
    if ([string]$state.settings.$key -notmatch '^(null|[A-Za-z0-9_.,/$:-]+)$') { throw "Saved preference $key is invalid." }
}
foreach ($key in $allowed) {
    $parts = $key.Split('/')
    Restore-Setting $parts[0] $parts[1] ([string]$state.settings.$key)
}
$component = [string]$state.home
$out = Invoke-Tv "cmd package set-home-activity --user 0 $component"
if ($out -match 'Error|Exception') { throw 'Restoring the original Home failed; choose it from Android settings.' }
$resolved = Invoke-Tv 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME'
if ($resolved -notmatch [regex]::Escape($component)) { throw 'Could not verify the original Home preference.' }
[void](Invoke-Tv 'input keyevent KEYCODE_HOME')
Write-Host 'Original Home, screensaver, timeout and animation preferences restored. Installed apps and theme files are retained.'
