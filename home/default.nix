{ config, pkgs, ... }:

{
  imports = [
    ./zsh.nix
  ];

  programs.fzf.enable = true;

  home.stateVersion = "23.11";

  home.packages = [ 
  ];

  programs.home-manager.enable = true;
}