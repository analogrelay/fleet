{ pkgs, pkgs-analogrelay, ... }:

{
  imports =
    [ ../../platform.nix
      ../../realms/microsoft.nix
      ../../roles/workstation.nix

      ../../users/ashleyst.nix
    ];

  networking.hostName = "ashleyst-omegaprime";
  wsl.defaultUser = "ashleyst";
 
  system.stateVersion = "23.11";

  home-manager.extraSpecialArgs = {
    username = "ashleyst";
  };
}
