function devshell {
  [CmdletBinding(DefaultParameterSetName = "List")]
  param(
    [Parameter(ParameterSetName = "Enter", Position = 0)]
    [string]$Instance,

    [Parameter(ParameterSetName = "Enter", Position = 1)]
    [Alias("Arch")]
    [string]$Architecture
  )

  if ($PSCmdlet.ParameterSetName -eq "List") {
    $latestPrerelease = Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest
    $latestStable = Get-VSSetupInstance -All | Select-VSSetupInstance -Latest
    $community = Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Community"
    $enterprise = Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Enterprise"
    $professional = Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Professional"

    Get-VSSetupInstance -All -Prerelease | ForEach-Object {
      $aliases = @()
      if ($_.InstanceId -eq $latestPrerelease.InstanceId) {
        $aliases += "latest"
      }
      if ($_.InstanceId -eq $latestStable.InstanceId) {
        $aliases += "stable"
      }
      if ($_.InstanceId -eq $community.InstanceId) {
        $aliases += "community"
      }
      if ($_.InstanceId -eq $enterprise.InstanceId) {
        $aliases += "enterprise"
      }
      if ($_.InstanceId -eq $professional.InstanceId) {
        $aliases += "professional"
      }

      $obj = [PSCustomObject]@{
        Aliases    = $aliases;
        InstanceId = $_.InstanceId;
        Product    = $_.Product.Id;
        Version    = $_.InstallationVersion;
      }
      $obj
    }
  }
  elseif ($PSCmdlet.ParameterSetName -eq "Enter") {
    if(!$Architecture) {
      $Architecture = $env:PROCESSOR_ARCHITECTURE ?? "Default"
    }
    
    $vsInstance = switch ($Instance) {
      "latest" { Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest }
      "stable" { Get-VSSetupInstance -All | Select-VSSetupInstance -Latest }
      "community" { Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Community" }
      "enterprise" { Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Enterprise" }
      "pro" { Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Professional" }
      "professional" { Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest -Product "Microsoft.VisualStudio.Product.Professional" }
      Default {
        Get-VSSetupInstance -All -Prerelease | Where-Object { $_.InstanceId -eq $Instance }
      }
    }
    if ($vsInstance) {
      Write-Host "Entering DevShell for $($vsInstance.Product.Id) instance '$($vsInstance.InstanceId)'..."
      Enter-VsDevShell -VsInstanceId $vsInstance.InstanceId -Arch $Architecture
    }
    else {
      Write-Error "No instance found with id '$Instance'"
    }
  }
}