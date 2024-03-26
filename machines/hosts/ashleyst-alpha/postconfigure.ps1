# Drop a file to redirect the profile to the fleet profile

$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.FullName

$profileScriptContent = ". '$RepoRoot\powershell\profile.ps1'"
$profileScriptContent | Out-File -FilePath $profile -Encoding utf8

$OhMyPosh = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\bin\oh-my-posh.exe"
if (Test-Path $OhMyPosh) {
  # Install Monaspice fonts if necessary
  $monaspaceFont = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Microsoft\Windows\Fonts\MonaspiceNeNerdFontMono-Medium.otf"
  if (-not (Test-Path $monaspaceFont)) {
    Write-Host "Installing Monaspice fonts..."
    & $OhMyPosh font install --user Monaspace
  }
}

# Symlink Windows Terminal settings
$wtSettingsDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$wtSettingsFile = $wtSettingsDir + "\settings.json"
if (-not (Test-Path $wtSettingsFile)) {
  Write-Host "Windows Terminal settings not found at $wtSettingsFile. Skipping."
} else {
  $wtFleetSettingsFile = "$RepoRoot\windows\terminal\settings.json"
  if (Test-Path $wtFleetSettingsFile) {
    if (Test-Path $wtSettingsFile) {
      Remove-Item -Path $wtSettingsFile
    }
    New-Item -Path $wtSettingsFile -ItemType SymbolicLink -Value $wtFleetSettingsFile
  }
}

# Check the machine name
$ExpectedMachineName = "ashleyst-alpha"
$CurrentMachineName = & hostname
if ($ExpectedMachineName -ne $CurrentMachineName) {
  Write-Host "Renaming machine..."
  Rename-Computer -NewName $ExpectedMachineName
}