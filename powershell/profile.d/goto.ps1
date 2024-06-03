$GotoRoots = @(
  $GeneralCodePath,
  $PersonalCodePath,
  $WorkCodePath,
  $env:USERPROFILE
)

function goto([string]$query) {
  if (!(Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "fzf is not installed. Please install it to use goto."
    return
  }

  # Collect candidate directories
  $candidates = @()
  foreach($root in $GotoRoots) {
    $localCandidates = Get-ChildItem $root -Directory -Depth 1 | Select-Object -ExpandProperty FullName
    $candidates += $localCandidates
  }

  # Now use fzf to select the directory
  $match = $candidates | fzf --height 20% --border rounded --query="$query" --select-1
  if ($match) {
    Set-Location $match
  } else {
    Write-Host "No directory selected."
  }
}