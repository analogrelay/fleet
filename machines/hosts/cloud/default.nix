{ pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../platform.nix
      ../../realms/analoghome.nix
      ../../roles/workstation.nix

      ../../users

      ../../profiles/desktop-environment.nix
      ../../profiles/gaming.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "cloud";
  boot.kernelPackages = pkgs.linuxPackages_6_13;
  boot.loader.grub.device = "nodev";

  system.stateVersion = "24.11";

  fleet.admin = "ashley";
}