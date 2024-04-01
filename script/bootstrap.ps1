$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.FullName


if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
    Write-Host "This script is only for Windows"
    exit 1
}

Write-Host "Bootstrapping Fleet configuration..."

# First, check for the winget command
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget is not available. Launching Microsoft store to install App Installer Package."
    Write-Host "Re-run this script when winget is available."
    Start-Process "ms-windows-store://pdp?productid=9nblggh4nns1"
    exit 1
}

# Now, install minimum required software
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    winget install -e Microsoft.PowerShell --source winget --no-upgrade
}

if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install -e Git.Git --source winget --no-upgrade
}

winget install -e AgileBits.1Password --source winget --no-upgrade

# Install OpenSSH Preview (to fix issues with Git)
winget install -e Microsoft.OpenSSH.Beta --source winget

# Disable the SSH Agent (we're going to use 1Password)
$svc = Get-Service ssh-agent -ErrorAction SilentlyContinue
if($svc -and ($svc.StartupType -ne "Disabled")) {
    Write-Host "Disabling OpenSSH SSH Agent Service (requires Admin)..."
    Start-Process powershell -Verb runas -ArgumentList @("-Command", "Set-Service ssh-agent -StartupType Disabled")
}

if($svc -and ($svc.Status -eq "Running")) {
    Write-Host "Stopping OpenSSH SSH Agent Service (requires Admin)..."
    Start-Process powershell -Verb runas -ArgumentList @("-Command", "Stop-Service ssh-agent")
}

# Check if the P:\ Drive exists
if (-not (Test-Path P:\)) {
    # It does not. We can't create the drive from a script very easily so just ask the user to.
    Write-Host "Create a data drive for personal code, bound to P:\ to continue"
    Write-Host "Once the drive is ready, re-run the bootstrap script."
    Start-Process "ms-settings:disksandvolumes"
    exit 1
}

# Make sure we're using Windows OpenSSH
git config --global core.sshCommand "$((Get-Command ssh).Path.Replace("\", "/"))"

# Clone the fleet repo
if(-not (Test-Path P:\analogrelay\fleet)) {
    if (-not (Test-Path P:\analogrelay)) {
        New-Item -Type Directory P:\analogrelay
    }
    Set-Location P:\analogrelay
    git clone git@github.com:analogrelay/fleet.git
}

if(-not (Test-Path P:\analogrelay\fleet\script\rebuild.ps1)) {
    throw "Couldn't find rebuild script"
}

# Prompt for this machine's hostname
$myHostname = Read-Host "What hostname do you want to use for this machine?"
& P:\analogrelay\fleet\script\rebuild.ps1 $myHostName

# # Launch the rebuild script in powershell core
# $pfDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)
# $powerShellCore = Join-Path $pfDir "PowerShell\7\pwsh.exe"
# if (Test-Path $powerShellCore) {
#     & $powerShellCore -File "$RepoRoot\script\rebuild.ps1"
# } else {
#     Write-Host "PowerShell Core didn't install properly."
#     exit 1
# }