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