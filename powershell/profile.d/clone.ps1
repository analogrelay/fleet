$CloneOrgMappings = @{
  "Microsoft" = $WorkCodePath;
  "Azure" = $WorkCodePath;
}

$DefaultGitHubRoot = $PersonalCodePath
$DefaultAzDoRoot = $WorkCodePath

function clone([string]$RepoSpec, [switch]$WhatIf) {
  if ($RepoSpec -match "https://((?<username>[^@]+)@)?dev.azure.com/(?<org>[^/]+)/(?<project>[^/]+)/_git/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $project = $Matches["project"]
    $repo = $Matches["repo"]
    $username = $Matches["username"]
    $root = $DefaultAzDoRoot
    $url = "https://$username@dev.azure.com/$org/$project/_git/$repo"
    $subpath = Join-Path $org $project $repo
  } elseif ($RepoSpec -match "https://(?<org>[^/\.]+).visualstudio.com/DefaultCollection/(?<project>[^/]+)/_git/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $project = $Matches["project"]
    $repo = $Matches["repo"]
    $root = $DefaultAzDoRoot
    $url = "https://$org.visualstudio.com/DefaultCollection/$project/_git/$repo"
    $subpath = Join-Path $org $project $repo
  } elseif ($RepoSpec -match "https://(?<org>[^/\.]+).visualstudio.com/(?<project>[^/]+)/_git/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $project = $Matches["project"]
    $repo = $Matches["repo"]
    $root = $DefaultAzDoRoot
    $url = "https://$org.visualstudio.com/DefaultCollection/$project/_git/$repo"
    $subpath = Join-Path $org $project $repo
  } elseif ($RepoSpec -match "git@ssh.dev.azure.com:v3/(?<org>[^/]+)/(?<project>[^/]+)/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $project = $Matches["project"]
    $repo = $Matches["repo"]
    $root = $DefaultAzDoRoot
    $url = "git@ssh.dev.azure.com:v3/$org/$project/$repo"
    $subpath = Join-Path $org $project $repo
  } elseif ($RepoSpec -match "(https?://github.com/|git@github.com:)?(?<org>[^/]+)/(?<repo>[^/]+)") {
    $org = $Matches["org"]
    $repo = $Matches["repo"]
    $root = $DefaultGitHubRoot
    if ($repo.EndsWith(".git")) {
      $repo = $repo.Substring(0, $repo.Length - 4)
    }
    $url = "git@github.com:$org/$repo.git"
    $subpath = Join-Path $org $repo
  } else {
    Write-Host "Invalid repository specification: $RepoSpec"
    return
  }

  $root = $CloneOrgMappings[$org] ?? $root
  $destination = Join-Path $root $subpath

  if (Test-Path $destination) {
    Write-Host "Destination $destination already exists. Changing directory."
    if (!$WhatIf) {
      Set-Location $destination
    }
    return
  }

  Write-Host "Cloning $org / $repo from $url to $destination ..."

  if (!$WhatIf) {
    # Get the immediate parent of the destination,
    $parent = Split-Path $destination -Parent
    if (-not (Test-Path $parent)) {
      New-Item -Path $parent -ItemType Directory
    }

    # Clone!
    git clone $url $destination

    # And go there.
    Set-Location $destination
  }
}