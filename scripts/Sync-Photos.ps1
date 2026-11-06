param([Parameter(Mandatory = $true)][string]$TvHost, [switch]$Start)
. (Join-Path $PSScriptRoot 'Common.ps1')
[void](Assert-Device 'portronics-beem-440' $TvHost)
Save-DeviceBackup 'portronics-beem-440' $TvHost
# Run in this scope so the hash fallback is visible to the unmodified official script.
if (-not (Get-Command Get-FileHash -ErrorAction SilentlyContinue)) {
    function Get-FileHash([string]$Path, [string]$Algorithm = 'SHA256') {
        $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
        $stream = [System.IO.File]::OpenRead($Path)
        try { [pscustomobject]@{ Hash = [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-', ''); Path = $Path; Algorithm = $Algorithm } }
        finally { $stream.Dispose(); $hasher.Dispose() }
    }
}
$arguments = @{ TvHost = $TvHost; Folder = (Join-Path $script:SetupRoot 'screensaver\pictures'); Seconds = 30; IdleMinutes = 2; Start = $Start }
Push-Location
try { & (Join-Path $script:UpstreamRoot 'addons\photo-screensaver\sync.ps1') @arguments }
finally { Pop-Location }
Write-Host 'Photos selected: 30 seconds per picture after two idle minutes.'
