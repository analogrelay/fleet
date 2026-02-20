{ ... }:

{
  imports = [
    ../../platform.nix
    ../../realms/analoghome.nix
    ../../roles/workstation.nix

    ../../profiles/tailnet.darwin.nix

    ../../users/ashley.nix
  ];

  networking.computerName = "Sephiroth";
  networking.hostName = "sephiroth";

  system.stateVersion = 4;

  fleet.admin = "ashley";
}
