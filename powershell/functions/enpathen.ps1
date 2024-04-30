function enpathen {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
  )

  $Paths | ForEach-Object {
    $path = $_
    if (-not (Test-Path $path)) {
      Write-Host "Path '$path' does not exist."
      return
    }

    $env:PATH += ";$path"
    Write-Host "Added '$path' to PATH."
  }
}

function depathen {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Paths
  )

  $Paths | ForEach-Object {
    $path = $_
    if (-not (Test-Path $path)) {
      Write-Host "Path '$path' does not exist."
      return
    }

    $env:PATH = $env:PATH -replace ";$path", ""
    Write-Host "Removed '$path' from PATH."
  }
}