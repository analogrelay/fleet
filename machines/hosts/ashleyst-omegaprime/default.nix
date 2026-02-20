{ config, ... }:

{
  imports =
    [ ../../platform.nix

      ../../users/ashleyst.nix
    ];

  fleet.identity = "ashleyst-omegaprime";
  networking.hostName = config.fleet.identity;
  wsl.defaultUser = "ashleyst";
 
  system.stateVersion = "23.11";

  fleet.admin = "ashleyst";
  fleet.platform = "wsl";
  fleet.role = "workstation";
  fleet.realm = "microsoft";
}
