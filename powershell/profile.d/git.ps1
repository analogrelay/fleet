$DefaultUserPrefixes = @("analogrelay", "anurse", "ashleyst")

function clean-branches {
  param(
    [string[]]$UserPrefixes = $DefaultUserPrefixes,
    [int]$MaxAgeDays = 30
  )

  function parsebranch($branch) {
    if($branch.StartsWith("*")) {
      $branch = $branch.Substring(1)
    }
    $branch = $branch.Trim()

    $parts = $branch.Split("/", 2, "None")
    if ($parts.Length -eq 1) {
      $parts = @($null, $parts[0])
    }
    if($parts[0] -eq 'users') {
      $parts = @($parts[1].Split("/", 2, "None"))
    }
    [PSCustomObject]@{
      Date = $null
      User = $parts[0]
      Name = $parts[1]
      FullName = $branch
      State = $null
      Subject = $null
      Author = $null
      PR = $null
    }
  }

  Write-Host "Collecting branch data. This can take a few seconds to query the GitHub API and check for Pull Requests..."

  $mergedLocals = $(git branch --merged | ForEach-Object { parsebranch $_ } | Where-Object { $null -ne $_ } | ForEach-Object { $_.State = "MERGED"; $_ })
  $branchesByAge = $(git for-each-ref --no-merged=HEAD --sort=committerdate refs/heads/ --format='%(committerdate:iso-strict) %(refname:short) %(contents:subject) - %(authorname)' | ForEach-Object {
    $parts = $_.Split(" ", 3, "None")
    $date = [DateTime]::Parse($parts[0])
    $branch = parsebranch $parts[1]
    $subjectAndAuthor = $parts[2].Split(" - ", 2, "None")
    $subject = $subjectAndAuthor[0]
    $author = $subjectAndAuthor[1]

    # For unmerged branches, we check for pull requests.
    $PrData = $(gh pr list --head $branch.FullName --state all --json "number,state,title" 2>$null | ConvertFrom-Json)

    [PSCustomObject]@{
      Date = $date
      User = $branch.User
      Name = $branch.Name
      FullName = $branch.FullName
      State = ($null -ne $PrData) ? $PrData.state : $null
      Subject = $subject
      Author = $author
      PR = ($null -ne $PrData) ? $PrData.number : $null
    }
  })

  $candidateBranches = ($mergedLocals + $mergedRemotes + $branchesByAge) | Where-Object { 
    ($UserPrefixes -contains $_.User) -and ($_.State -ne "OPEN") -and (($_.State -eq "MERGED") -or ($_.Date -lt (Get-Date).AddDays(-$MaxAgeDays)))
  } | Sort-Object -Property Date

  if($candidateBranches.Count -eq 0) {
    Write-Host "No branches to delete."
    return
  }

  Write-Host "The following branches are candidates for deletion:"
  $candidateBranches | Format-Table -AutoSize

  if((Read-Host "Delete these branches? (y/n)") -ne "y") {
    Write-Host "Aborting branch deletion."
    return
  }

  $candidateBranches | ForEach-Object {
    git branch -D $_.FullName
  }
}