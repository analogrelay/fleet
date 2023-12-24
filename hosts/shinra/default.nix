# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../modules/users/ashley.nix
      ../../modules/nixos.nix
      ../../modules/server.nix
      ../../modules/k3s/agent.nix
      ../../modules/tailnet.nix
    ];

  networking.hostName = "shinra";

  system.stateVersion = "23.11";
}

