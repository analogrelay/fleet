{ pkgs, pkgs-analogrelay, ... }:

{
  imports =
    [ ../../platform.nix
      ../../realms/microsoft.nix
      ../../roles/workstation.nix

      ../../users/ashleyst.nix
    ];

  networking.hostName = "ashleyst-alphaprime";
  wsl.defaultUser = "ashleyst";
 
  system.stateVersion = "23.11";

  home-manager.extraSpecialArgs = {
    username = "ashleyst";
  };

  environment.systemPackages = [
    pkgs-analogrelay.jetbrains.rust-rover
  ];
}
