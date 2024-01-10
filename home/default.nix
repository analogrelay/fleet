{ pkgs, role, os, wsl, lib, ... }:

let
  commonImports = [
    ./${os}.nix
    ./roles/${role}.nix
    ./roles/${role}.${os}.nix

    ./profiles/shell.nix
    ./profiles/git.nix
    ./profiles/vim.nix
    ./profiles/ssh.nix
    ./profiles/tmux.nix
  ];
  nonWslImports = if (!wsl) then [
    ./profiles/vscode.nix
  ] else [];
  wslImports = if (wsl) then [
    ./profiles/wsl.nix
  ] else [];
  allImports = commonImports ++ nonWslImports ++ wslImports;
in
{
  imports = allImports;

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