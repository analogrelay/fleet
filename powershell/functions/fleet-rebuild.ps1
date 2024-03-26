# Add a fleet-rebuild command to rebuild this machine from configuration
function fleet-rebuild([string]$HostName = $env:COMPUTERNAME) {
  Push-Location $FleetRoot
  try {
    & script/rebuild.ps1 $HostName
  } finally {
    Pop-Location
  }
}