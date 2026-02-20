{ ... }:

{
  imports = [
    ../../platform.nix

    ../../profiles/tailnet.darwin.nix

    ../../users/ashley.nix
  ];

  networking.computerName = "Sephiroth";
  networking.hostName = "sephiroth";

  system.stateVersion = 4;

  fleet.admin = "ashley";
  fleet.platform = "darwin";
  fleet.role = "workstation";
  fleet.realm = "analoghome";
}
