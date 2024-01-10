{ pkgs, lib, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    _1password
  ];
}