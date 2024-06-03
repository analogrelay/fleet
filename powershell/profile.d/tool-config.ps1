if (Get-Command bat -ErrorAction SilentlyContinue) {
  Set-Alias cat bat
}
if (Get-Command eza -ErrorAction SilentlyContinue) {
  $env:EZA_COLORS="di=1;37:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
  Set-Alias ls eza
}
if (Get-Command rg -ErrorAction SilentlyContinue) {
  Set-Alias grep rg
}