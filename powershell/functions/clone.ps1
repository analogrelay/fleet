$CloneOrgMappings = @{
  "Microsoft" = $WorkCodePath;
  "Azure" = $WorkCodePath;
  "msdata" = $WorkCodePath;
  "" = $PersonalCodePath;
}

function clone([string]$RepoSpec) {
  if ($RepoSpec -match "https://((?<username>[^@]+)@)?dev.azure.com/(?<org>[^/]+)/(?<project>[^/]+)/_git/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $project = $Matches["project"]
    $repo = $Matches["repo"]
    $url = "git@ssh.dev.azure.com:v3/$org/$project/$repo"
    $subpath = Join-Path $org $project $repo
  } elseif ($RepoSpec -match "git@ssh.dev.azure.com:v3/(?<org>[^/]+)/(?<project>[^/]+)/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $project = $Matches["project"]
    $repo = $Matches["repo"]
    $url = "git@ssh.dev.azure.com:v3/$org/$project/$repo"
    $subpath = Join-Path $org $project $repo
  } elseif ($RepoSpec -match "(https?://github.com/|git@github.com:)?(?<org>[^/]+)/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $repo = $Matches["repo"]
    if ($repo.EndsWith(".git")) {
      $repo = $repo.Substring(0, $repo.Length - 4)
    }
    $url = "git@github.com:$org/$repo.git"
    $subpath = Join-Path $org $repo
  } else {
    Write-Host "Invalid repository specification: $RepoSpec"
    return
  }

  $root = $CloneOrgMappings[$org] ?? $CloneOrgMappings[""] ?? $GeneralCodePath
  $destination = Join-Path $root $subpath

  if (Test-Path $destination) {
    Write-Host "Destination $destination already exists. Changing directory."
    Set-Location $destination
  }

  Write-Host "Cloning $org / $repo from $url to $destination ..."

  # Get the immediate parent of the destination,
  $parent = Split-Path $destination -Parent
  if (-not (Test-Path $parent)) {
    New-Item -Path $parent -ItemType Directory
  }

  # Clone!
  git clone $url $destination
}