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
FUNCS_TO_AUTOLOAD=("''${(@f)$(find "$HOME/.config/zsh/functions" \! -name "*.*")}")
for func in $FUNCS_TO_AUTOLOAD; do
    autoload $func
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

if type -p oh-my-posh > /dev/null; then
  eval "$(oh-my-posh init zsh --config ~/.config/analogposh.omp.json)"
fi
