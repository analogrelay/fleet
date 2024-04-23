# Make sure we know where the code is
$global:GeneralCodePath = Join-Path $env:USERPROFILE "Code"
$global:PersonalCodePath = $GeneralCodePath
$global:WorkCodePath = $GeneralCodePath

if (Get-PSDrive P -ErrorAction SilentlyContinue) {
  $global:PersonalCodePath = "P:\"
}
if (Get-PSDrive W -ErrorAction SilentlyContinue) {
  $global:WorkCodePath = "W:\"
}
