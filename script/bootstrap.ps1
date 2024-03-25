$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.FullName

if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
    Write-Host "This script is only for Windows"
    exit 1
}

Write-Host "Bootstrapping Fleet configuration..."

# First, check for the winget command
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget is not available. Automatic bootstrap is not possible."
    exit 1
}

# Import the base package set
winget import -i "$RepoRoot\winget\base.pkgs.json" --ignore-versions

# Launch the rebuild script in powershell core
$pfDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)
$powerShellCore = Join-Path $pfDir "PowerShell\7\pwsh.exe"
if (Test-Path $powerShellCore) {
    & $powerShellCore -File "$RepoRoot\script\rebuild.ps1"
} else {
    Write-Host "PowerShell Core didn't install properly."
    exit 1
}