param(
    [Parameter(Mandatory = $true)][ValidateSet('portronics-beem-440', 'tcl-uniontv')][string]$Profile,
    [Parameter(Mandatory = $true)][string]$TvHost
)
. (Join-Path $PSScriptRoot 'Common.ps1')
$info = Assert-Device $Profile $TvHost
Save-DeviceBackup $Profile $TvHost
$source = Join-Path $info.Folder 'launcher-config.xml'
if (-not (Test-Path -LiteralPath $source)) { throw 'The profile launcher configuration is missing.' }
# Parse before replacing the build input.
[void]([xml](Get-Content -LiteralPath $source -Raw))
$target = Join-Path $script:UpstreamRoot 'launcher\app\src\main\res\values\config.xml'
$lockDirectory = Join-Path $script:SetupRoot '.local-state'
[void](New-Item -ItemType Directory -Path $lockDirectory -Force)
$lock = [System.IO.File]::Open((Join-Path $lockDirectory 'launcher-build.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
$original = [System.IO.File]::ReadAllBytes($target)
$savedSkip = $env:SKIP_BUILD
$savedGradleOpts = $env:GRADLE_OPTS
try {
    Remove-Item Env:SKIP_BUILD -ErrorAction SilentlyContinue
    $env:GRADLE_OPTS = "$savedGradleOpts -Dorg.gradle.daemon=false".Trim()
    [System.IO.File]::WriteAllBytes($target, [System.IO.File]::ReadAllBytes($source))
    Invoke-UpstreamScript 'launcher\build-and-install.ps1' @('-TvHost', $TvHost, '-StockLauncher', 'none')
} finally {
    [System.IO.File]::WriteAllBytes($target, $original)
    $lock.Dispose()
    if ($null -eq $savedSkip) { Remove-Item Env:SKIP_BUILD -ErrorAction SilentlyContinue } else { $env:SKIP_BUILD = $savedSkip }
    if ($null -eq $savedGradleOpts) { Remove-Item Env:GRADLE_OPTS -ErrorAction SilentlyContinue } else { $env:GRADLE_OPTS = $savedGradleOpts }
}
Write-Host 'Installed with the original launcher preserved. Test the real Home/arrow/OK buttons, video and sound.'
