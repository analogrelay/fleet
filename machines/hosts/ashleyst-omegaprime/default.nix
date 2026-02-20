{ ... }:

{
  imports =
    [ ../../platform.nix

      ../../users/ashleyst.nix
    ];

  networking.hostName = "ashleyst-omegaprime";
  wsl.defaultUser = "ashleyst";
 
  system.stateVersion = "23.11";

  fleet.admin = "ashleyst";
  fleet.platform = "wsl";
  fleet.role = "workstation";
  fleet.realm = "microsoft";
}
