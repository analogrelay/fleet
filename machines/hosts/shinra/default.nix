{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../platform.nix
    ../../users
    ../../services/homedb.nix
  ];

  networking.hostName = "shinra";

  # Enable linger so systemd user services (e.g. fleet-sync timer) run
  # without an active login session.
  users.users.ashley.linger = true;

  system.stateVersion = "25.11";

  # shinra is a laptop running with lid closed
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
}
