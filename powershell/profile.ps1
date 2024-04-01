$FleetRoot = (Get-Item $PSScriptRoot).Parent.FullName

# Initialize Oh My Posh
$configFile = Join-Path $FleetRoot "powershell" "analogposh.omp.json"
(@(& oh-my-posh.exe init pwsh --config="$configFile" --print) -join "`n") | Invoke-Expression

oh

# Make sure we know where the code is
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

if (Get-Command bat -ErrorAction SilentlyContinue) {
  Set-Alias cat bat
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
  Set-Alias ls eza
}

oh-my-posh completion powershell | Out-String | Invoke-Expression