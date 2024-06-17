{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../hardware/rpi4.nix

      ../../users/ashley.nix

      ../../roles/server.nix

      ../../profiles/k3s/agent.nix
    ];

  networking.hostName = "tifa";

  system.stateVersion = "23.11";

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };
}

