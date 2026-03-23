# Terminal background colors per host
typeset -A _host_colors
_host_colors=(
  sephiroth "#1e1e1e"
  cloud     "#1a1a2e"
  scarlet   "#2e1a1a"
  avalanche "#1a2a2e"
  shinra    "#2e2a1a"
)

_default_bg="#1e1e1e"

_set_bg() {
  local color="$1"
  if [[ -n "$TMUX" ]]; then
    printf '\ePtmux;\e\e]11;%s\e\e\\\e\\' "$color"
  else
    printf '\e]11;%s\e\\' "$color"
  fi
}

_update_bg_for_host() {
  local host="${HOST%%.*}"
  local color="${_host_colors[$host]:-$_default_bg}"
  _set_bg "$color"
}

# Set bg on shell startup
_update_bg_for_host

autoload -Uz add-zsh-hook
add-zsh-hook precmd _update_bg_for_host
