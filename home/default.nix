{ pkgs, role, os, wsl, username, ... }:

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
    
    ./users/${username}.nix
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
  home.username = username;
  home.homeDirectory = /home/${username};

  programs.home-manager.enable = true;
  programs.ssh.enable = true;
  programs.fzf.enable = true;
  programs.gpg.enable = true;
  programs.password-store.enable = true;

  home.packages = with pkgs; [
    dos2unix
    eza
    direnv
    _1password
  ];

  home.file.".local/bin" = {
    source = ../bin;
    recursive = true;
    executable = true;
  };
  home.sessionPath = [ "$HOME/.local/bin" ];
}