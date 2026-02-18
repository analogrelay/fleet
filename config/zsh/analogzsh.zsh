if [ -d /home/linuxbrew/.linuxbrew ]; then
  # Enable Linuxbrew, if installed.
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if type direnv; then
  eval "$(direnv hook zsh)"
fi

try_brew() {
  if type -p brew > /dev/null; then
    brew $@
  fi
}

# Mark all files with no extension in the 'functions' directory as autoloaded
fpath=("$HOME/.config/zsh/functions" $fpath)
for func in "$HOME"/.config/zsh/functions/*(N); do
    [[ "${func:t}" = *.* ]] && continue
    autoload -Uz "${func:t}"
done

# Load Git keys
if [ -f ~/.ssh/git_signing ]; then
  ssh-add ~/.ssh/git_signing
fi

if type -p eza > /dev/null; then
  alias ls="eza"
fi

if type -p bat > /dev/null; then
  alias cat="bat"
fi

if [ -f /Applications/Zed.app/Contents/MacOS/cli ]; then
  alias zed="/Applications/Zed.app/Contents/MacOS/cli"
fi

if type -p jj > /dev/null; then
  source <(jj util completion zsh)
fi

if type -p oh-my-posh > /dev/null; then
  eval "$(oh-my-posh init zsh --config ~/.config/analogposh.omp.json)"
fi

if [ -f /etc/paths ]; then
  while read p; do
    PATH="$PATH:$p"
  done < /etc/paths
fi

if [ -d /etc/paths.d ]; then
  for p in /etc/paths.d/*; do
    if [ -r $p ]; then
      PATH="$PATH:$(cat $p)"
    fi
  done
fi