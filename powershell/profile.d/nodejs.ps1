if (Get-Command fnm -ErrorAction SilentlyContinue) {
  (@(& fnm env --shell power-shell) -join "`n") | Invoke-Expression
}
