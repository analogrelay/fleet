{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
    };
  };
}