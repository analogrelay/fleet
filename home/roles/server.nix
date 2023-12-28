{ pkgs, lib, ... }:

{
  imports = [
    ../profiles/shell.nix
  ];

  home.packages = with pkgs; [
    _1password
  ];
}