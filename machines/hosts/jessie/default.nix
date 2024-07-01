{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../hardware/rpi4.nix
      ../../platform.nix

      ../../users

      ../../roles/server.nix
    ];

  networking.hostName = "jessie";

  system.stateVersion = "23.11";

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };
}

