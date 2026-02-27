{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../platform.nix
    ../../users
    ../../services/traefik.nix
  ];

  networking.hostName = "shinra";

  system.stateVersion = "24.05";

  # shinra is a laptop running with lid closed
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
}
