# Initialize Oh My Posh
$configFile = Join-Path $FleetRoot "home" "analogposh.omp.json"
(@(& oh-my-posh.exe init pwsh --config="$configFile" --print) -join "`n") | Invoke-Expression

oh-my-posh completion powershell | Out-String | Invoke-Expression