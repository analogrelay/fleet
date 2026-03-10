<#
.SYNOPSIS
  Rebuilds a host machine from its configuration.
.DESCRIPTION
  Rebuild the current system using the latest configuration.
.PARAMETER HostName
  The configuration name, in [user@]identity format.
  Defaults to the identity file ($env:LOCALAPPDATA\fleet\identity),
  then falls back to $env:COMPUTERNAME.
.PARAMETER NoConfirm
  Skip the confirmation prompt before rebuilding.
.PARAMETER DryRun
  Print what would be done but don't execute.
.PARAMETER NonInteractive
  Suppress all prompts (implies -NoConfirm).
#>
param(
  [Parameter(Position = 0)]
  [string]$HostName,

  [switch]$NoConfirm,
  [switch]$DryRun,
  [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

# Resolve repo root: prefer $env:FLEET_ROOT, then derive from script location
if ($env:FLEET_ROOT) {
  $RepoRoot = $env:FLEET_ROOT
} else {
  $RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.FullName
}

$InternalRepoRoot = Join-Path (Split-Path $RepoRoot) "fleet-internal"

if (!$IsCoreCLR) {
  throw "This script is only supported in PowerShell Core."
}
if (!$IsWindows) {
  throw "This script is only supported on Windows. Use the unix rebuild script instead."
}

if ($NonInteractive) { $NoConfirm = $true }

# --- Identity resolution ---

$IdentityFile = Join-Path $env:LOCALAPPDATA "fleet\identity"

if ($HostName) {
  # Extract identity from [user@]identity format
  if ($HostName -match '@') {
    $identity = ($HostName -split '@', 2)[1]
  } else {
    $identity = $HostName
  }
} elseif (Test-Path $IdentityFile) {
  $identity = (Get-Content -Path $IdentityFile -Raw).Trim()
  Write-Host "Using identity from $IdentityFile`: $identity"
} else {
  $identity = $env:COMPUTERNAME.ToLowerInvariant()
  Write-Host "No identity file found, using computer name: $identity"
}

if (-not $identity) {
  Write-Error "No fleet identity found.`nRun 'script\bootstrap.ps1' to set up your fleet identity,`nor pass the identity explicitly: script\rebuild.ps1 <identity>"
  exit 1
}

# --- Validate configuration exists ---

function _listAvailableHosts($rootPath) {
  $hostsDir = Join-Path $rootPath "machines\hosts"
  if (Test-Path $hostsDir) {
    Get-ChildItem -Path $hostsDir -Directory |
      Where-Object { Test-Path (Join-Path $_.FullName "configure.ps1") } |
      ForEach-Object { "  - $($_.Name)" }
  }
}

$configScript = Join-Path $RepoRoot "machines\hosts\$identity\configure.ps1"
if (-not (Test-Path $configScript)) {
  $available = _listAvailableHosts $RepoRoot
  Write-Error "No configuration found for identity '$identity'.`nAvailable hosts:`n$($available -join "`n")"
  exit 1
}

# --- Confirmation ---

Write-Host "Rebuilding system from configuration for $identity..."

if (-not $NoConfirm) {
  Write-Host -NoNewline "Continue? [Y/N] "
  $continue = Read-Host
  if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "Aborted."
    exit 1
  }
}

# --- Build host ---

function _buildhost($rootPath, $hostname, [switch]$Optional) {
  $hostConfigDir = Join-Path $rootPath "machines" "hosts" $hostname
  if (-not (Test-Path $hostConfigDir)) {
    if (-not $Optional) {
      Write-Warning "No configuration found for host $hostname at $hostConfigDir."
    }
    return
  }

  $script = Join-Path $hostConfigDir "configure.ps1"
  if (Test-Path $script) {
    if ($DryRun) {
      Write-Host "[dry-run] Would apply: $script"
    } else {
      Write-Host "Applying configuration from $script..."
      & $script
    }
  } elseif (-not $Optional) {
    throw "No configuration script found for host $hostname at $script."
  }
}

_buildhost $RepoRoot $identity
if (Test-Path $InternalRepoRoot) {
  _buildhost $InternalRepoRoot $identity -Optional
} else {
  Write-Warning "fleet-internal repository not found at $InternalRepoRoot."
}