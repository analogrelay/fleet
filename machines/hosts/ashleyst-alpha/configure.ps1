$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.FullName
Import-Module "$RepoRoot\powershell\module\Fleet.psd1" -Scope Local

# Set user-level environment variable to define key information about the machine.
Set-MachineContext -Name "ashleyst-alpha" -Role "workstation" -Realm "microsoft"

Update-MachineConfiguration
