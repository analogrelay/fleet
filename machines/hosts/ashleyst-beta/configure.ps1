$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.FullName

winget configure --file "$RepoRoot\machines\windows.dsc.yml"
winget configure --file "$RepoRoot\machines\roles\workstation.dsc.yml"
. "$RepoRoot\machines\roles\workstation.windows.ps1"