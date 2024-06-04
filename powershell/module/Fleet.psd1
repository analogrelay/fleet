@{
  RootModule           = 'Fleet.psm1'
  ModuleVersion        = '0.0.1'
  CompatiblePSEditions = @("Core")
  GUID                 = 'b814c265-7346-4025-93c9-0b946e4fbaaf'
  Author               = 'Ashley Stanton-Nurse <me@analogrelay.net>'
  Copyright            = '(c) Ashley Stanton-Nurse. All rights reserved.'
  FunctionsToExport    = @(
    'Set-MachineContext',
    'Set-EnvironmentVariable'
    'Update-MachineConfiguration'
  )
  CmdletsToExport      = @()
  VariablesToExport    = '*'
  AliasesToExport      = @()
  PrivateData          = @{
    PSData = @{
      # Tags = @()
      # LicenseUri = ''
      # ProjectUri = ''
      # IconUri = ''
      # ReleaseNotes = ''
      # Prerelease = ''
      # RequireLicenseAcceptance = $false
      # ExternalModuleDependencies = @()
    } # End of PSData hashtable
  } # End of PrivateData hashtable
}

