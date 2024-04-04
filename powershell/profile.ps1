$env:HOME = $env:USERPROFILE

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
  $env:EZA_COLORS="di=1;37:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
  Set-Alias ls eza
}

oh-my-posh completion powershell | Out-String | Invoke-Expression