# Offline checks only: no device connections and no local Python environment required.
param()
$ErrorActionPreference = 'Stop'
$errors = @()
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
    foreach ($failure in $parseErrors) { $errors += "$($file.Name): $($failure.Message)" }
}
if ($errors.Count) { throw ($errors -join "`n") }
. (Join-Path $PSScriptRoot 'Common.ps1')
foreach ($name in @('portronics-beem-440', 'tcl-uniontv')) {
    $info = Get-Profile $name
    [void]([xml](Get-Content -LiteralPath (Join-Path $info.Folder 'launcher-config.xml') -Raw))
    foreach ($line in Get-Content -LiteralPath (Join-Path $info.Folder 'debloat.txt')) {
        $package = ($line -replace '#.*$', '').Trim()
        if ($package -and $package -notmatch '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$') { throw "Invalid package in $name cleanup list." }
    }
}
foreach ($name in @('projector-sunrise-fast', 'cinematic-projector', 'cinematic-tcl')) {
    $config = Get-Content -LiteralPath (Join-Path $script:SetupRoot "themes\$name\config.json") -Raw | ConvertFrom-Json
    if (@($config.dock_apps).Count -ne 4) { throw "$name must contain four dock apps." }
}
# Exercise the firmware gate with a fake read-only transport. The mock refuses any
# command other than the four identity reads; these checks cannot write to a TV.
function Assert-Tools {}
$script:MockDevice = @{}
$script:MockReadCount = 0
function Invoke-Tv([string]$Command) {
    $script:MockReadCount++
    if (-not $script:MockDevice.ContainsKey($Command)) { throw "Unexpected command in offline test: $Command" }
    $script:MockDevice[$Command]
}
$savedTarget = $env:TV_HOST
$savedPort = $env:TV_PORT
try {
    foreach ($name in @('portronics-beem-440', 'tcl-uniontv')) {
        $device = (Get-Profile $name).Device
        $script:MockDevice = @{
            'getprop ro.build.version.release' = [string]$device.android
            'getprop ro.build.display.id' = [string]$device.build
            'getprop ro.product.model' = [string]$device.model
        }
        if ($device.PSObject.Properties['software_version'] -and $device.software_version) {
            $property = if ($device.PSObject.Properties['software_version_property']) { $device.software_version_property } else { 'ro.software.version_id' }
            $script:MockDevice["getprop $property"] = [string]$device.software_version
        }
        [void](Assert-Device $name 'test.invalid')
        foreach ($query in @($script:MockDevice.Keys)) {
            $originalValue = $script:MockDevice[$query]
            $script:MockDevice[$query] = 'unmatched-test-device'
            $rejected = $false
            try { [void](Assert-Device $name 'test.invalid') }
            catch { $rejected = $_.Exception.Message -match 'does not match|do not match|differs' }
            $script:MockDevice[$query] = $originalValue
            if (-not $rejected) { throw "Firmware guard did not reject $query for $name." }
        }
    }
    $script:MockReadCount = 0
    $rejected = $false
    try { [void](Assert-Device 'portronics-beem-440' 'invalid;target') }
    catch { $rejected = $_.Exception.Message -match 'without a port' }
    if (-not $rejected -or $script:MockReadCount -ne 0) { throw 'Invalid target was not rejected before transport access.' }
} finally {
    if ($null -eq $savedTarget) { Remove-Item Env:TV_HOST -ErrorAction SilentlyContinue } else { $env:TV_HOST = $savedTarget }
    if ($null -eq $savedPort) { Remove-Item Env:TV_PORT -ErrorAction SilentlyContinue } else { $env:TV_PORT = $savedPort }
}
if (Test-Path -LiteralPath (Join-Path $script:UpstreamRoot 'tools\restore.ps1')) {
    $tokens = $null
    $parseErrors = $null
    $restoreAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $script:UpstreamRoot 'tools\restore.ps1'), [ref]$tokens, [ref]$parseErrors)
    $parameters = @($restoreAst.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
    foreach ($name in @('List', 'Stock', 'TvHost')) {
        if ($parameters -notcontains $name) { throw "The upstream restore parameter $name is missing." }
    }
}
if (Test-Path -LiteralPath $script:SetupPython) {
    # record_path only computes a local filename; it does not open a TV connection.
    $list = Join-Path $script:SetupRoot 'profiles\portronics-beem-440\debloat.txt'
    $path = Get-RecoveryPath $list 'test.invalid'
    if ((Split-Path -Leaf $path) -notmatch '^recovery-test\.invalid-[0-9a-f]{8}\.json$') { throw 'The upstream recovery filename contract changed.' }
}
Write-Host 'Offline checks passed: syntax, profiles/XML, package names, themes, firmware mismatch refusal, target validation and available upstream recovery contracts. No device connections.'
