if (Get-Module VSSetup -ListAvailable) {
  Import-Module VSSetup
  $vsInstance = Get-VSSetupInstance -All -Prerelease | Select-VSSetupInstance -Latest
  if ($vsInstance) {
    $installPath = $vsInstance.InstallationPath
    $devShellPath = Join-Path $installPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Import-Module $devShellPath
  }
}