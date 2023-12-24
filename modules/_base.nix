{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    zsh
    nix-index
    tmux
    nix
  ];
}