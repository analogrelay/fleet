# Add a fleet-rebuild command to rebuild this machine from configuration
function fleet-rebuild([string]$HostName = $env:COMPUTERNAME) {
  Push-Location $FleetRoot
  try {
    & script/rebuild.ps1 $HostName
  } finally {
    Pop-Location
  }
}

function fleet-edit {
  if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    throw "Visual Studio Code is not installed. Please install it and try again."
  }
  code $FleetRoot
}

Set-Alias fledit fleet-edit