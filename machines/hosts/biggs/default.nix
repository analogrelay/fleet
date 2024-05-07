{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix
      ../../roles/server.nix

      ../../users/ashley.nix
    ];

  networking.hostName = "biggs";

  system.stateVersion = "23.11";

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };
}

