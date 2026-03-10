<#
.SYNOPSIS
  Bootstrap a Windows system with the fleet configuration.
.DESCRIPTION
  Installs prerequisites (PowerShell Core, Git, 1Password, OpenSSH), clones
  the fleet repo, writes the fleet identity, and delegates to script/rebuild.ps1.

  Can be run standalone:
    irm https://raw.githubusercontent.com/analogrelay/fleet/main/script/bootstrap.ps1 | iex

  Or from a local clone:
    script\bootstrap.ps1 [identity]
.PARAMETER Identity
  The fleet identity for this machine. Defaults to the local computer name.
  Written to $env:LOCALAPPDATA\fleet\identity for future rebuilds.
.PARAMETER Install
  Always use ~/.config/fleet as the fleet directory, even when running
  from a local clone elsewhere. Clones or updates the repo at that
  location so future rebuilds use the standard path.
.PARAMETER NoConfirm
  Skip the confirmation prompt before rebuilding.
#>
param(
  [Parameter(Position = 0)]
  [string]$Identity,

  [switch]$Install,

  [switch]$NoConfirm
)

$ErrorActionPreference = "Stop"

$FleetRepo = "https://github.com/analogrelay/fleet.git"
$FleetDir = Join-Path $env:USERPROFILE ".config\fleet"

# --- Helpers ---

function Log($msg) { Write-Host "==> $msg" }

# --- Platform check ---

if ([System.Environment]::OSVersion.Platform -ne "Win32NT") {
  Write-Error "This script is only for Windows. Use the bash bootstrap script instead."
  exit 1
}

Log "Bootstrapping Fleet configuration..."

# --- Resolve identity ---

if ($Identity) {
  # Extract identity from [user@]identity format
  if ($Identity -match '@') {
    $Identity = ($Identity -split '@', 2)[1]
  }
} else {
  $Identity = $env:COMPUTERNAME.ToLowerInvariant()
}

# Write identity file
$IdentityDir = Join-Path $env:LOCALAPPDATA "fleet"
$IdentityFile = Join-Path $IdentityDir "identity"
if (-not (Test-Path $IdentityDir)) {
  New-Item -Path $IdentityDir -ItemType Directory -Force | Out-Null
}
Set-Content -Path $IdentityFile -Value $Identity -NoNewline
Log "Fleet identity: $Identity"

# --- Install prerequisites ---

# Check for winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host "winget is not available. Launching Microsoft Store to install App Installer Package."
  Write-Host "Re-run this script when winget is available."
  Start-Process "ms-windows-store://pdp?productid=9nblggh4nns1"
  exit 1
}

# Install minimum required software
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
  Log "Installing PowerShell Core..."
  winget install -e Microsoft.PowerShell --source winget --no-upgrade
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Log "Installing Git..."
  winget install -e Git.Git --source winget --no-upgrade
}

Log "Installing 1Password..."
winget install -e AgileBits.1Password --source winget --no-upgrade

# Install OpenSSH Preview (to fix issues with Git)
Log "Installing OpenSSH Beta..."
winget install -e Microsoft.OpenSSH.Beta --source winget

# Disable the SSH Agent (we use 1Password's SSH agent instead)
$svc = Get-Service ssh-agent -ErrorAction SilentlyContinue
if ($svc -and ($svc.StartupType -ne "Disabled")) {
  Log "Disabling OpenSSH SSH Agent Service (requires Admin)..."
  Start-Process powershell -Verb runas -ArgumentList @("-Command", "Set-Service ssh-agent -StartupType Disabled")
}
if ($svc -and ($svc.Status -eq "Running")) {
  Log "Stopping OpenSSH SSH Agent Service (requires Admin)..."
  Start-Process powershell -Verb runas -ArgumentList @("-Command", "Stop-Service ssh-agent")
}

# Ensure we're using Windows OpenSSH for git
$sshCmd = Get-Command ssh -ErrorAction SilentlyContinue
if ($sshCmd) {
  git config --global core.sshCommand "$($sshCmd.Path.Replace("\", "/"))"
}

# --- Clone or locate fleet repo ---

if (-not $Install -and $PSScriptRoot -and (Test-Path (Join-Path (Split-Path $PSScriptRoot) "flake.nix"))) {
  # Running from inside the fleet repo and not forced to install to ~/.config/fleet
  $FleetDir = Split-Path $PSScriptRoot
  Log "Running from existing fleet repo at $FleetDir"
} elseif (Test-Path (Join-Path $FleetDir ".git")) {
  Log "Fleet repo already exists at $FleetDir, pulling latest..."
  git -C $FleetDir pull --ff-only 2>$null
} else {
  Log "Cloning fleet repo to $FleetDir..."
  $parentDir = Split-Path $FleetDir
  if (-not (Test-Path $parentDir)) {
    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
  }
  git clone $FleetRepo $FleetDir
}

# --- Validate configuration exists ---

$configScript = Join-Path $FleetDir "machines\hosts\$Identity\configure.ps1"
if (-not (Test-Path $configScript)) {
  $hostsDir = Join-Path $FleetDir "machines\hosts"
  $available = Get-ChildItem -Path $hostsDir -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "configure.ps1") } |
    ForEach-Object { "  - $($_.Name)" }
  Write-Error "No configuration found for identity '$Identity'.`nAvailable hosts with configure.ps1:`n$($available -join "`n")"
  exit 1
}
Log "Found configuration for '$Identity'"

# --- Run rebuild ---

$env:FLEET_ROOT = $FleetDir
$rebuildScript = Join-Path $FleetDir "script\rebuild.ps1"

$rebuildArgs = @($Identity, "-NoConfirm")
Log "Running script\rebuild.ps1 $($rebuildArgs -join ' ')..."
& $rebuildScript @rebuildArgs