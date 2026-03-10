# Initialize Oh My Posh
$configFile = Join-Path $FleetRoot "config" "analogposh.omp.json"
(@(& oh-my-posh.exe init pwsh --config="$configFile" --print) -join "`n") | Invoke-Expression