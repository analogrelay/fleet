<#
.SYNOPSIS
  Rebuilds a host machine from it's configuration.
.PARAMETER HostName
  The name of the host to rebuild. If not specified, the local host is used.
#>
param(
  [string]$HostName = $null
)

$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.FullName
$InternalRepoRoot = Join-Path (Get-Item -Path $RepoRoot).Parent.FullName "fleet-internal"
if(-not (Test-Path $InternalRepoRoot)) {
  Write-Warning "fleet-internal repository not found at $InternalRepoRoot."
}

if (!$IsCoreCLR) {
  throw "This script is only supported in PowerShell Core."
}
if (!$IsWindows) {
  throw "This script is only supported on Windows. Use the unix rebuild script instead."
}

if (!$HostName) {
  $HostName = $env:COMPUTERNAME.ToLowerInvariant()
}

Write-Host "Rebuilding system from configuration for $HostName..."
Write-Host -NoNewline "Continue? [Y/N] "
$continue = Read-Host
if ($continue -ne "Y" -and $continue -ne "y") {
  Write-Host "Aborted."
  exit 1
}

function _buildhost($rootPath, $hostname) {
  # Find the host in 'machines/hosts'
  $hostConfigDir = Join-Path $rootPath "machines" "hosts" $hostname
  if (-not (Test-Path $hostConfigDir)) {
    throw "No configuration found for host $hostname found at $hostConfigDir."
  }

  # First, run a 'preconfigure.ps1' script if it exists
  $preconfigureScript = Join-Path $hostConfigDir "preconfigure.ps1"
  if (Test-Path $preconfigureScript) {
    Write-Host "Running preconfigure script..."
    & $preconfigureScript
  }

  # Now, run the DSC configuration
  $dscConfig = Join-Path $hostConfigDir "configuration.dsc.yaml"
  if (Test-Path $dscConfig) {
    Write-Host "Applying WinGet configuration..."
    winget configure --file "$dscConfig"
  }

  # Now, run a 'postconfigure.ps1' script if it exists
  $configureScript = Join-Path $hostConfigDir "postconfigure.ps1"
  if (Test-Path $configureScript) {
    Write-Host "Running postconfigure script..."
    & $configureScript
  }
}

_buildhost $RepoRoot $HostName
if(Test-Path $InternalRepoRoot) {
  _buildhost $InternalRepoRoot $HostName
}