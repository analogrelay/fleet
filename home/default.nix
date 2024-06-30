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

  programs.home-manager.enable = true;
  programs.ssh.enable = true;
  programs.fzf.enable = true;
  programs.gpg.enable = true;
  programs.eza = {
    enable = true;
    git = true;
    icons = true;
  };
  programs.bat.enable = true;
  programs.password-store.enable = true;
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    dos2unix
    direnv
    _1password
  ];

  home.file.".local/bin" = {
    source = ../bin;
    recursive = true;
    executable = true;
  };
  home.sessionPath = [ "$HOME/.local/bin" ];
  home.sessionVariables = {
    EZA_COLORS = "di=1;37:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43";
  };
}