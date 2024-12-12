#!/usr/bin/env bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
dotfiles_root="$(dirname $(dirname $(dirname $script_dir)))"
cd "$dotfiles_root"

if type -p nix >/dev/null; then
  echo "Nix is already installed. Skipping..."
else
  echo "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi

if nix-channel --list | grep home-manager >/dev/null; then
  echo "Home Manager channel already added. Skipping..."
else
  echo "Adding Home Manager channel..."
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
fi

nix-channel --update

if type -p home-manager >/dev/null; then
  echo "Home Manager is already installed. Skipping..."
else
  echo "Installing Home Manager..."
  nix-shell '<home-manager>' -A install
fi

configuration_name="$(whoami)@$(hostname)"
if [ "$CODESPACES" = "1" ]; then
  configuration_name="codespaces"
fi

echo "Switching to home-manager configuration $configuration_name..."
home-manager switch --flake ".#$configuration_name" -b backup

