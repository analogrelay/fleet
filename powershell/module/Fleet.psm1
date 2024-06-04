$FleetRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
Export-ModuleMember -Variable FleetRoot

function Set-MachineContext {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Role,
        [Parameter(Mandatory=$true)][string]$Realm,
        [Parameter(Mandatory=$false)][string[]]$Profiles
    )

  Set-EnvironmentVariable "FLEET_ROLE" "workstation" -Target "User"
  Set-EnvironmentVariable "FLEET_MACHINE" "ashleyst-delta" -Target "User"
  Set-EnvironmentVariable "FLEET_REALM" "microsoft" -Target "User"

  if ($Profiles) {
    Set-EnvironmentVariable "FLEET_PROFILES" ([string]::Join(";", $Profiles)) -Target "User"
  }
}

function Set-EnvironmentVariable {
    param(
        [Parameter(Mandatory=$true, Position=0)][string]$Name,
        [Parameter(Mandatory=$true, Position=1)][string]$Value,
        [Parameter(Mandatory=$false)][System.EnvironmentVariableTarget]$Target = "User"
    )

    [System.Environment]::SetEnvironmentVariable($Name, $Value, $Target)
    if ($Target -ne 'Process') {
      Set-Variable -Name "env:$Name" -Value $Value -Scope Global
    }
}

function Update-MachineConfiguration {
  param(
    [Parameter(Mandatory=$false)][string]$MachineName = $env:FLEET_MACHINE,
    [Parameter(Mandatory=$false)][string]$Role = $env:FLEET_ROLE,
    [Parameter(Mandatory=$false)][string]$Realm = $env:FLEET_REALM,
    [Parameter(Mandatory=$false)][string[]]$Profiles
  )

  if(-not $Profiles) {
    $Profiles = $env:FLEET_PROFILES -split ';'
  }

  function applyconfig($config) {
    if (Test-Path $config) {
      Write-Host "Applying configuration file $config ..."
      & $config
    } else {
      Write-Warning "Missing configuration file $config"
    }
  }

  applyconfig "$FleetRoot\machines\windows.ps1"
  applyconfig "$FleetRoot\machines\realms\$Realm.windows.ps1"
  applyconfig "$FleetRoot\machines\roles\$Role.windows.ps1"

  $Profiles | Where-Object { -not [string]::IsNullOrWhitespace($_) } | ForEach-Object {
    applyconfig "$FleetRoot\machines\profiles\$_.windows.ps1"
  }
}