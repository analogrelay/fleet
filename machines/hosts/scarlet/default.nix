{ pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../platform.nix
      ../../realms/analoghome.nix

      ../../users
    ];

  networking.hostName = "scarlet";

  system.stateVersion = "24.11";

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };
}

