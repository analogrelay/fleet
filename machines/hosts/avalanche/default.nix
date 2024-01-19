{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix
      ../../roles/server.nix

      ../../users

      ../../profiles/syncthing.nix
      ../../profiles/nas.nix
      ../../profiles/k3s/server.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "avalanche";

  system.stateVersion = "23.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}

