{ pkgs, lib, ... }:

{
  imports = [
    ../profiles/shell.nix
    ../profiles/vscode.nix
  ];

  home.packages = with pkgs; [
    _1password
  ];
}