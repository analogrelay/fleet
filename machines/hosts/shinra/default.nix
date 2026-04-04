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

  fleet.secrets."cloudflared-tunnel-creds" = {
    source = "op://Fleet/CloudflareTunnel-Shinra/tunnel-creds";
  };
	fleet.secrets."cloudflared-tunnel-cert.pem" = {
		source = "op://Fleet/CloudflareTunnel-Shinra/tunnel-cert.pem";
	};
	services.cloudflared = {
		enable = true;
		certificateFile = config.fleet.secrets."cloudflared-tunnel-cert.pem".path;
		tunnels."a0c39510-6e96-42ed-a58d-7a18c465b173" = {
			credentialsFile = config.fleet.secrets."cloudflared-tunnel-creds".path;
			default = "http_status:404";
		};
	};
	systemd.services."cloudflared-tunnel-a0c39510-6e96-42ed-a58d-7a18c465b173".after = [
		"provision-fleet-secrets.service"
	];

	services.alloy.enable = true;
	environment.etc."alloy/config.alloy".path = ./config.alloy;
}
