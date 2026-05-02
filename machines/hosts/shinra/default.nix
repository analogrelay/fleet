{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../platform.nix
    ../../users

    ../../services/fail2ban.nix
    ../../services/grafana.nix
    ../../services/loki.nix
    ../../services/prometheus.nix
    ../../services/home-monitoring
  ];

  networking.hostName = "shinra";
  networking.firewall.allowedTCPPorts = [ 3001 ];

  # Enable linger so systemd user services (e.g. fleet-sync timer) run
  # without an active login session.
  users.users.ashley.linger = true;

  system.stateVersion = "25.11";

  # shinra is a laptop running with lid closed
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  services.alloy.enable = true;
  systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];
  systemd.services.alloy.serviceConfig.AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
  environment.etc."alloy/config.alloy".source = ./config.alloy;
}
