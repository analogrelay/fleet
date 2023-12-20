# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../modules/users.nix
      ../../modules/base.nix
      ../../modules/server.nix
      ../../modules/k3s/server.nix
      ../../modules/tailnet.nix
    ];

  networking.hostName = "avalanche";
  networking.domain = "home.analogrelay.net";

  time.timeZone = "America/Vancouver";

  system.stateVersion = "23.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}

