{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix
      ../../roles/server.nix

      ../../users/ashley.nix
      ../../users/mary.nix

      ../../profiles/nas.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "avalanche";

  system.stateVersion = "23.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}

