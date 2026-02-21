{ pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../platform.nix

      ../../users
      ../../users/kiosk.nix

      ../../profiles/desktop-environment.nix
      ../../profiles/gaming.nix
      ../../profiles/tailnet.nix
      ../../profiles/syncthing.nix
    ];

  networking.hostName = "scarlet";

  system.stateVersion = "24.11";

  services.blueman.enable = true;

  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "kiosk";
  };

  # Create data directories
  systemd.tmpfiles.rules = [
    "d /data 2774 share share - -"
  ];
}

