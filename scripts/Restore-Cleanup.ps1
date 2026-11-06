param(
    [Parameter(Mandatory = $true)][ValidateSet('portronics-beem-440', 'tcl-uniontv')][string]$Profile,
    [Parameter(Mandatory = $true)][string]$TvHost
)
. (Join-Path $PSScriptRoot 'Common.ps1')
$info = Assert-Device $Profile $TvHost
$list = Join-Path $info.Folder 'debloat.txt'
$record = Get-RecoveryPath $list $TvHost
if (-not (Test-Path -LiteralPath $record)) {
    throw 'The official recovery record is missing for this checkout and address. Restore it from your private backup; this wrapper refuses an enable-everything fallback.'
}
$stock = if ($Profile -eq 'portronics-beem-440') { 'com.htc.htclauncherhighenglishd08' } else { 'com.google.android.tvlauncher' }
Invoke-UpstreamScript 'tools\restore.ps1' @('-TvHost', $TvHost, '-Stock', $stock, $list)
Write-Host 'Recorded cleanup states restored. Use Restore-Preferences.ps1 to restore the pre-setup Home/screensaver/system preferences.'
