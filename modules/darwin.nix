{ config, lib, pkgs, ... }:

{
  imports = [
    ./_base.nix
  ];

  services.nix-daemon.enable = true;
}