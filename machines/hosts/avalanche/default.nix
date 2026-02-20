{ config, pkgs, ... }:

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

  fleet.identity = "avalanche";
  networking.hostName = config.fleet.identity;
  networking.hostId = "19cc4826";

  system.stateVersion = "24.11";

  fleet.admin = "ashley";
  fleet.platform = "nixos";
  fleet.role = "server";
  fleet.realm = "analoghome";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_1.gasket
    zfs
  ];
}

