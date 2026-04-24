{ ... }:

{
  imports = [
    ../../platform.nix

    ../../profiles/tailnet.darwin.nix

    ../../users/ashley.nix
  ];

  networking.computerName = "Tifa";
  networking.hostName = "tifa";

  system.stateVersion = 5;
  system.primaryUser = "ashley";

  security.pam.services.sudo_local.enable = true;
  security.pam.services.sudo_local.reattach = true;
  security.pam.services.sudo_local.watchIdAuth = true;
}
