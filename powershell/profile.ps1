$env:HOME = $env:USERPROFILE

$FleetRoot = (Get-Item $PSScriptRoot).Parent.FullName

# Run Profile Scripts
Get-ChildItem "$FleetRoot\powershell\profile.d" -Filter '*.ps1' | ForEach-Object {
  . $_
}