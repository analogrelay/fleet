

# Initialize Oh My Posh
(@(& oh-my-posh.exe init pwsh --config='' --print) -join "`n") | Invoke-Expression

# Make sure we know where the code is
$FleetRoot = (Get-Item $PSScriptRoot).Parent.FullName
$GeneralCodePath = Join-Path $env:USERPROFILE "Code"
$PersonalCodePath = $GeneralCodePath
$WorkCodePath = $GeneralCodePath

if (Get-PSDrive P -ErrorAction SilentlyContinue) {
  $PersonalCodePath = "P:\"
}
if (Get-PSDrive W -ErrorAction SilentlyContinue) {
  $WorkCodePath = "W:\"
}

if (Get-Command fnm -ErrorAction SilentlyContinue) {
  (@(& fnm env --shell power-shell) -join "`n") | Invoke-Expression
}

Get-ChildItem (Join-Path $PSScriptRoot "functions") -Filter '*.ps1' | ForEach-Object {
  . $_
}