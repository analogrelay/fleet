{ pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../profiles/tailnet.nix
    ];

  networking.hostName = "avalanche";

  # Enable linger so systemd user services (e.g. fleet-sync timer) run
  # without an active login session.
  users.users.ashley.linger = true;
  networking.hostId = "19cc4826";

  system.stateVersion = "25.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_1.gasket
    zfs
  ];
}

