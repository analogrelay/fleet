{ ... }:

{
  imports =
    [ ../../platform.nix
      ../../roles/server.nix

      ../../users/ashley.nix
    ];

  networking.hostName = "jessie";

  system.stateVersion = "23.11";

  # No need to compress, we're just going to burn it immediately
  sdImage.compressImage = false;
}

