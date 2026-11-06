param(
    [Parameter(Mandatory = $true)][ValidateSet('portronics-beem-440', 'tcl-uniontv')][string]$Profile,
    [Parameter(Mandatory = $true)][string]$TvHost,
    [ValidateSet('Sunrise', 'Cinematic')][string]$Look,
    [switch]$FastAnimations
)
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $Look) { $Look = if ($Profile -eq 'portronics-beem-440') { 'Sunrise' } else { 'Cinematic' } }
if ($Profile -eq 'tcl-uniontv' -and $Look -eq 'Sunrise') { throw 'Sunrise contains projector app IDs. Use the TCL Cinematic profile on the TCL TV.' }
$folder = if ($Look -eq 'Sunrise') { 'projector-sunrise-fast' } elseif ($Profile -eq 'tcl-uniontv') { 'cinematic-tcl' } else { 'cinematic-projector' }
[void](Assert-Device $Profile $TvHost)
Save-DeviceBackup $Profile $TvHost
Invoke-UpstreamScript 'tools\theme.ps1' @('-TvHost', $TvHost, (Join-Path $script:SetupRoot "themes\$folder"))
if ($FastAnimations) {
    foreach ($key in @('window_animation_scale', 'transition_animation_scale', 'animator_duration_scale')) {
        [void](Invoke-Tv "settings put global $key 0.5")
        if ((Invoke-Tv "settings get global $key") -ne '0.5') { throw "Could not verify animation setting $key." }
    }
}
Write-Host 'Theme applied. Original system preferences remain saved under .local-state.'
