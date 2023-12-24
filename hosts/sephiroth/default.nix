{ config, pkgs, ... }:

{
  imports = [
    ../../modules/users/ashley.nix
    ../../modules/darwin.nix
  ];

  networking.computerName = "Sephiroth";
  networking.hostName = "sephiroth";

  security.pam.enableSudoTouchIdAuth = true;

  system.stateVersion = 4;
}