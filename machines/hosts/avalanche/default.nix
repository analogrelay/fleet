{ pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../profiles/syncthing.nix
      ../../profiles/nas.nix
      ../../profiles/k3s/server.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "avalanche";
  networking.hostId = "19cc4826";

  system.stateVersion = "24.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_1.gasket
    zfs
  ];
}

