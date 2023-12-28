{ pkgs, ... }:

{
  imports = [
    ../profiles/shell.nix
    ../profiles/vscode.nix
  ];

  programs.fzf.enable = true;

  home.packages = with pkgs; [
    microsoft-edge-stable
  ];
}
