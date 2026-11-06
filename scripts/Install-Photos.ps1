param([Parameter(Mandatory = $true)][string]$TvHost)
. (Join-Path $PSScriptRoot 'Common.ps1')
[void](Assert-Device 'portronics-beem-440' $TvHost)
Save-DeviceBackup 'portronics-beem-440' $TvHost
$savedGradleOpts = $env:GRADLE_OPTS
try {
    $env:GRADLE_OPTS = "$savedGradleOpts -Dorg.gradle.daemon=false".Trim()
    Invoke-UpstreamScript 'addons\photo-screensaver\build-and-install.ps1' @('-TvHost', $TvHost)
} finally {
    if ($null -eq $savedGradleOpts) { Remove-Item Env:GRADLE_OPTS -ErrorAction SilentlyContinue } else { $env:GRADLE_OPTS = $savedGradleOpts }
}
Write-Host 'Photos installed from source. Run Sync-Photos.ps1 to send the collection and select it as screensaver.'
