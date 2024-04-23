$env:HOME = $env:USERPROFILE

$FleetRoot = (Get-Item $PSScriptRoot).Parent.FullName

# Run Profile Scripts
Get-ChildItem "$FleetRoot\powershell\profile.d" -Filter '*.ps1' | ForEach-Object {
  . $_
}

Get-ChildItem (Join-Path $PSScriptRoot "functions") -Filter '*.ps1' | ForEach-Object {
  . $_
}