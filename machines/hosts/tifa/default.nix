{ ... }:

{
  imports = [
    ../../platform.nix

    ../../profiles/tailnet.darwin.nix

    ../../users/ashley.nix
  ];

  networking.computerName = "Tifa";
  networking.hostName = "tifa";

  system.stateVersion = 4;
}
