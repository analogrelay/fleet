{ pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../platform.nix
      ../../realms/analoghome.nix
      ../../roles/workstation.nix

      ../../users
      ../../users/kiosk.nix

      ../../profiles/desktop-environment.nix
      ../../profiles/gaming.nix
      ../../profiles/tailnet.nix
      ../../profiles/syncthing.nix
    ];

  networking.hostName = "scarlet";

  system.stateVersion = "24.11";

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };

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

