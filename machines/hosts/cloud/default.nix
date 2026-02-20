{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../profiles/desktop-environment.nix
      ../../profiles/gaming.nix
      ../../profiles/tailnet.nix
    ];

  fleet.identity = "cloud";
  networking.hostName = config.fleet.identity;
  boot.kernelPackages = pkgs.linuxPackages_6_13;
  boot.loader.grub.device = "nodev";

  system.stateVersion = "24.11";

  fleet.admin = "ashley";
  fleet.platform = "nixos";
  fleet.role = "workstation";
  fleet.realm = "analoghome";
}