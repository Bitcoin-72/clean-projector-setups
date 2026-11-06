# Creates only this checkout's Python environment. Install JDK/Android SDK separately.
param([string]$Python = 'python')
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-Upstream
& $Python -c 'import sys; assert sys.version_info >= (3, 10), "Python 3.10 or newer is required"'
if ($LASTEXITCODE -ne 0) { throw 'Python 3.10+ is required; pass its executable using -Python.' }
if (-not (Test-Path -LiteralPath $script:SetupPython)) {
    & $Python -m venv (Join-Path $script:UpstreamRoot 'tools\venv')
    if ($LASTEXITCODE -ne 0) { throw 'Creating the local Python environment failed.' }
}
& $script:SetupPython -m pip install -r (Join-Path $script:UpstreamRoot 'tools\requirements.txt')
if ($LASTEXITCODE -ne 0) { throw 'Installing the local Python dependencies failed.' }
Write-Host 'Python tools are ready. Building apps additionally requires JDK 17 and Android SDK platform/build-tools 34.'
