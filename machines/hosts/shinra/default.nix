{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users/ashley.nix

      ../../roles/server.nix

      ../../profiles/k3s/agent.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "shinra";

  system.stateVersion = "23.11";
}

