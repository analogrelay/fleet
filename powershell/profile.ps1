$env:HOME = $env:USERPROFILE

Import-Module "$PSScriptRoot\module\Fleet.psd1" -Scope Global

# Run Profile Scripts
Get-ChildItem "$FleetRoot\powershell\profile.d" -Filter '*.ps1' | ForEach-Object {
  . $_
}