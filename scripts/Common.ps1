# Shared helpers. Dot-source this file; it does not connect to a device by itself.
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:ExpectedUpstream = '1937c8048672d4c322e70fe805bda1175f546716'
$script:SetupRoot = Split-Path -Parent $PSScriptRoot
$script:UpstreamRoot = Join-Path $script:SetupRoot 'upstream'
$script:SetupPython = Join-Path $script:UpstreamRoot 'tools\venv\Scripts\python.exe'
$script:Utf8 = New-Object System.Text.UTF8Encoding $false

function Assert-Upstream {
    if (-not (Test-Path -LiteralPath (Join-Path $script:UpstreamRoot 'tools\tv.py'))) {
        throw 'Initialize the source first: git submodule update --init --recursive'
    }
    $head = (& git -C $script:UpstreamRoot rev-parse HEAD) -join ''
    if ($LASTEXITCODE -ne 0 -or $head.Trim() -ne $script:ExpectedUpstream) {
        throw "The upstream checkout must be pinned to $script:ExpectedUpstream. Run git submodule update --init --recursive."
    }
}

function Assert-Tools {
    Assert-Upstream
    if (-not (Test-Path -LiteralPath $script:SetupPython)) {
        throw 'Run scripts\Initialize.ps1 first to create the local Python environment.'
    }
}

function Get-Profile([string]$Profile) {
    if ($Profile -ne 'portronics-beem-440') { throw 'Unknown device profile.' }
    $folder = Join-Path $script:SetupRoot "profiles\$Profile"
    $deviceFile = Join-Path $folder 'device.json'
    if (-not (Test-Path -LiteralPath $deviceFile)) { throw "Missing profile metadata: $deviceFile" }
    $device = Get-Content -LiteralPath $deviceFile -Raw | ConvertFrom-Json
    foreach ($key in @('android', 'build', 'model')) {
        if (-not $device.PSObject.Properties[$key] -or -not [string]$device.$key) { throw "Profile metadata requires $key." }
    }
    [pscustomobject]@{ Name = $Profile; Folder = $folder; Device = $device }
}

function Set-DeviceTarget([string]$TvHost) {
    # No port, shell syntax or embedded credentials. These tested profiles use port 5555.
    if ($TvHost -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]*$') { throw 'Pass the device IP address or hostname without a port.' }
    $env:TV_HOST = $TvHost
    $env:TV_PORT = '5555'
}

function Invoke-Tv([string]$Command) {
    $result = & $script:SetupPython -I (Join-Path $script:UpstreamRoot 'tools\tv.py') $Command
    if ($LASTEXITCODE -ne 0) { throw 'The device command failed. No further steps were sent.' }
    ($result -join "`n").Trim()
}

function Assert-Device([string]$Profile, [string]$TvHost) {
    Assert-Tools
    Set-DeviceTarget $TvHost
    $profileInfo = Get-Profile $Profile
    $actual = @{
        android = Invoke-Tv 'getprop ro.build.version.release'
        build = Invoke-Tv 'getprop ro.build.display.id'
        model = Invoke-Tv 'getprop ro.product.model'
    }
    foreach ($key in @('android', 'build', 'model')) {
        if ($actual[$key] -cne [string]$profileInfo.Device.$key) {
            throw "This device does not match profile $Profile ($key differs). No changes were made."
        }
    }
    if ($profileInfo.Device.PSObject.Properties['software_version'] -and $profileInfo.Device.software_version) {
        $property = 'ro.software.version_id'
        if ($profileInfo.Device.PSObject.Properties['software_version_property']) { $property = [string]$profileInfo.Device.software_version_property }
        if ($property -notmatch '^ro\.[A-Za-z0-9_.]+$') { throw 'Invalid software version property in device.json.' }
        if ((Invoke-Tv "getprop $property") -cne [string]$profileInfo.Device.software_version) {
            throw "This firmware does not match profile $Profile. No changes were made."
        }
    }
    $profileInfo
}

function Get-StateDirectory([string]$Profile, [string]$TvHost) {
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { $digest = [BitConverter]::ToString($algorithm.ComputeHash($script:Utf8.GetBytes($TvHost))).Replace('-', '').Substring(0, 16).ToLowerInvariant() }
    finally { $algorithm.Dispose() }
    $path = Join-Path $script:SetupRoot ".local-state\$Profile\$digest"
    [void](New-Item -ItemType Directory -Path $path -Force)
    $path
}

function Save-OriginalState([string]$Profile, [string]$TvHost) {
    $stateDirectory = Get-StateDirectory $Profile $TvHost
    $stateFile = Join-Path $stateDirectory 'before.json'
    if (Test-Path -LiteralPath $stateFile) { return $stateFile }
    $home = Invoke-Tv 'cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME'
    $home = @($home -split "`n" | Where-Object { $_ -match '^[A-Za-z_][\w.]*/[\w.$]+$' }) | Select-Object -Last 1
    if (-not $home) { throw 'Could not identify the current Home; no changes were made.' }
    $settings = [ordered]@{}
    foreach ($key in @('window_animation_scale', 'transition_animation_scale', 'animator_duration_scale')) {
        $settings["global/$key"] = Invoke-Tv "settings get global $key"
    }
    foreach ($key in @('screensaver_components', 'screensaver_default_component', 'screensaver_enabled')) {
        $settings["secure/$key"] = Invoke-Tv "settings get secure $key"
    }
    $settings['system/screen_off_timeout'] = Invoke-Tv 'settings get system screen_off_timeout'
    $state = [ordered]@{ profile = $Profile; host = $TvHost; captured_utc = [DateTime]::UtcNow.ToString('o'); home = $home; settings = $settings }
    [System.IO.File]::WriteAllText($stateFile, ($state | ConvertTo-Json -Depth 5), $script:Utf8)
    Write-Host "Original preferences saved privately in $stateFile"
    $stateFile
}

function Save-DeviceBackup([string]$Profile, [string]$TvHost) {
    [void](Save-OriginalState $Profile $TvHost)
    $folder = Join-Path (Get-StateDirectory $Profile $TvHost) ("backup-" + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff'))
    [void](New-Item -ItemType Directory -Path $folder)
    $queries = [ordered]@{
        'packages.txt' = 'pm list packages -f'
        'disabled-packages.txt' = 'pm list packages -d'
        'getprop.txt' = 'getprop'
        'settings-global.txt' = 'settings list global'
        'settings-secure.txt' = 'settings list secure'
        'settings-system.txt' = 'settings list system'
    }
    foreach ($name in $queries.Keys) { [System.IO.File]::WriteAllText((Join-Path $folder $name), (Invoke-Tv $queries[$name]), $script:Utf8) }
    Write-Host "Private device backup: $folder"
}

function Invoke-UpstreamScript([string]$RelativePath, [object[]]$ScriptArguments) {
    $scriptPath = Join-Path $script:UpstreamRoot $RelativePath
    if (-not (Test-Path -LiteralPath $scriptPath)) { throw "Missing upstream script: $RelativePath" }
    # A separate process contains upstream exit statements and location changes.
    $shell = (Get-Process -Id $PID).Path
    & $shell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @ScriptArguments
    if ($LASTEXITCODE -ne 0) { throw "$RelativePath failed (exit $LASTEXITCODE)." }
}

function Get-RecoveryPath([string]$List, [string]$TvHost) {
    $tools = Join-Path $script:UpstreamRoot 'tools'
    $code = 'import sys; sys.path.insert(0, sys.argv[1]); import recovery; print(recovery.record_path(sys.argv[2], sys.argv[3]))'
    $path = (& $script:SetupPython -I -c $code $tools $List $TvHost) -join ''
    if ($LASTEXITCODE -ne 0 -or -not $path) { throw 'Could not locate the official recovery record.' }
    $path.Trim()
}

function Restore-Setting([string]$Namespace, [string]$Name, [string]$Value) {
    if ($Value -eq 'null') { [void](Invoke-Tv "settings delete $Namespace $Name") }
    else {
        if ($Value -notmatch '^[A-Za-z0-9_.,/$:-]+$') { throw "Invalid saved value for $Name; nothing was sent for this setting." }
        [void](Invoke-Tv "settings put $Namespace $Name '$Value'")
    }
    if ((Invoke-Tv "settings get $Namespace $Name") -cne $Value) { throw "Could not verify restored setting $Name." }
}
