{ pkgs, config, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../profiles/tailnet.nix

			../../services/fail2ban.nix
			../../services/sillytavern.nix
			../../services/caddy.nix
			../../services/oauth2-proxy.nix
			../../services/postgres.nix
			../../services/redis.nix
			../../services/paperless.nix
			../../services/keycloak.nix
			../../services/ledger.nix
			../../services/radarr.nix
			../../services/wal-g.nix
			../../services/syncthing.nix
    ];

  networking.hostName = "avalanche";

  # Enable linger so systemd user services (e.g. fleet-sync timer) run
  # without an active login session.
  users.users.ashley.linger = true;
  networking.hostId = "19cc4826";

  system.stateVersion = "25.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_1.gasket
    zfs
  ];

	services.samba = {
		enable = true;
		openFirewall = true;
		settings = {
			global = {
				workgroup = "GAIA";
				"server string" = config.networking.hostName;
				"netbios name" = config.networking.hostName;
				security = "user";
				"guest account" = "nobody";
			};
			homes = {
				path = "/mnt/tank/homes/%S";
				browsable = true;
				"read only" = false;
				"create mask" = "0700";
				"directory mask" = "0700";
			};
			media = {
				path = "/mnt/tank/media";
				browsable = true;
				"read only" = false;
				"create mask" = "0775";
				"directory mask" = "0775";
				"force user" = "share";
				"force group" = "share";
			};
			backups = {
				path = "/mnt/tank/backups";
				browsable = true;
				"read only" = false;
				"create mask" = "0775";
				"directory mask" = "0775";
				"force user" = "share";
				"force group" = "share";
			};
			public = {
				path = "/mnt/tank/shares/public";
				browsable = true;
				"read only" = false;
				"create mask" = "0775";
				"directory mask" = "0775";
				"force user" = "share";
				"force group" = "share";
			};
		};
	};

  fleet.secrets."cloudflared-tunnel-creds" = {
    source = "op://Fleet/CloudflareTunnel-Avalanche/tunnel-creds";
  };
	fleet.secrets."cloudflared-tunnel-cert.pem" = {
		source = "op://Fleet/CloudflareTunnel-Avalanche/tunnel-cert.pem";
	};
	services.cloudflared = {
		enable = true;
		certificateFile = config.fleet.secrets."cloudflared-tunnel-cert.pem".path;
		tunnels."a0306444-7c05-4c03-9152-d6c09e116854" = {
			credentialsFile = config.fleet.secrets."cloudflared-tunnel-creds".path;
			default = "http_status:404";
		};
	};
	systemd.services."cloudflared-tunnel-a0306444-7c05-4c03-9152-d6c09e116854".after = [
		"provision-fleet-secrets.service"
	];

	services.alloy.enable = true;
	systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];
	systemd.services.alloy.serviceConfig.AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
	environment.etc."alloy/config.alloy".source = ./config.alloy;
}

