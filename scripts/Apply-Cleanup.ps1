param(
    [Parameter(Mandatory = $true)][ValidateSet('portronics-beem-440')][string]$Profile,
    [Parameter(Mandatory = $true)][string]$TvHost
)
. (Join-Path $PSScriptRoot 'Common.ps1')
$info = Assert-Device $Profile $TvHost
Save-DeviceBackup $Profile $TvHost
$list = Join-Path $info.Folder 'debloat.txt'
try { Invoke-UpstreamScript 'tools\disable.ps1' @('-TvHost', $TvHost, $list) }
finally {
    $record = Get-RecoveryPath $list $TvHost
    if (Test-Path -LiteralPath $record) { Copy-Item -LiteralPath $record -Destination (Join-Path (Get-StateDirectory $Profile $TvHost) 'cleanup-recovery.json') -Force }
}
Write-Host 'Cleanup applied using the upstream package guards and per-device recovery record.'
