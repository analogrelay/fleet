{ ... }:

{
  imports =
    [ ../../platform.nix

      ../../users/ashleyst.nix
    ];

  networking.hostName = "ashleyst-omegaprime";
  wsl.defaultUser = "ashleyst";

  system.stateVersion = "23.11";
}
