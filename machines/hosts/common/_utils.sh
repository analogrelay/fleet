make_link() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ]; then
    return
  fi

  if [ -e "$target" ]; then
    echo "Backing up existing $target..."
    mv "$target" "$target.bak"
  fi

  target_base=$(dirname $target)
  if [ ! -d $target_base ]; then
    mkdir -p "$target_base"
  fi

  ln -s "$source" "$target"
}