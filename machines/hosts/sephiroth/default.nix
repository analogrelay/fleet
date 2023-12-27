{ ... }:

{
  imports = [
      ../../platform.nix
    ../../roles/workstation.nix

    ../../users/ashley.nix
  ];

  networking.computerName = "Sephiroth";
  networking.hostName = "sephiroth";

  system.stateVersion = 4;
}
