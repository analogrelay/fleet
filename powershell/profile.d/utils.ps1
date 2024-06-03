filter ts() {
  "$(Get-Date -Format u): $_"
}

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

function chbr($query = "") {
  $branch = git branch --all | fzf --height 20% --border rounded --query="$query" --select-1
  if(!$branch) {
    Write-Host "No branch selected."
    return
  }
  $branch = $branch.Trim()

  if ($branch -match "remotes/origin/(?<branch>.+)") {
    $branch = $Matches["branch"]
  }
  git checkout $branch
}