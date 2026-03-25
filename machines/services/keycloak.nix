{ pkgs, ... }:

{
	# ── fail2ban: ban IPs after repeated Keycloak login failures ──────────
	services.fail2ban.jails.keycloak.settings = {
		enabled      = true;
		maxretry     = 5;
		filter       = "keycloak";
		action       = "cloudflare-list";
		backend      = "systemd";
		journalmatch = "_SYSTEMD_UNIT=keycloak.service";
	};

	environment.etc."fail2ban/filter.d/keycloak.local".text =
		''
		[Definition]
		failregex = type="LOGIN_ERROR",.* realmName="(?P<realm>[^"]+)",.* ipAddress="<HOST>"
		ignoreregex =
		'';

  services.postgresql.ensureDatabases = [ "keycloak" ];
  services.postgresql.ensureUsers = [
    {
      name = "keycloak";
      ensureDBOwnership = true;
    }
  ];

	services.cloudflared.tunnels."a0306444-7c05-4c03-9152-d6c09e116854".ingress = {
		"id.analogrelay.net" = "http://localhost:23912";
	};

	services.keycloak = {
		enable = true;
		plugins = [
			pkgs.keycloak.plugins.junixsocket-common
			pkgs.keycloak.plugins.junixsocket-native-common
		];
		database = {
			type = "postgresql";
			username = "keycloak";
			host = "/run/postgresql";
		};
		settings = {
			hostname = "https://id.analogrelay.net";
			http-host = "0.0.0.0";
			http-port = 23912;
			http-enabled = true;
			proxy-headers = "xforwarded";
			proxy-trusted-addresses="::1/128,127.0.0.0/8";
		};
	};
}
