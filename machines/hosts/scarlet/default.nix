{ pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../platform.nix

      ../../users
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "scarlet";

  system.stateVersion = "25.11";
}

