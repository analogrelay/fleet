{ config, ... }:

{
  imports = [
    ../../platform.nix

    ../../profiles/tailnet.darwin.nix

    ../../users/ashley.nix
  ];

  fleet.identity = "sephiroth";
  networking.computerName = "Sephiroth";
  networking.hostName = config.fleet.identity;

  system.stateVersion = 4;

  fleet.admin = "ashley";
  fleet.platform = "darwin";
  fleet.role = "workstation";
  fleet.realm = "analoghome";
}
