{ pkgs, role, os, ... }:

{
  imports = [
    ./${os}.nix
    ./roles/${role}.nix
    ./roles/${role}.${os}.nix

    ./profiles/git.nix
    ./profiles/vim.nix
    ./profiles/ssh.nix
    ./profiles/tmux.nix
  ];

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
  programs.ssh.enable = true;
  programs.fzf.enable = true;

  home.packages = with pkgs; [
    dos2unix
    eza
    direnv
  ];

  home.file.".local/bin" = {
    source = ../bin;
    recursive = true;
    executable = true;
  };
  home.sessionPath = [ "$HOME/.local/bin" ];
}