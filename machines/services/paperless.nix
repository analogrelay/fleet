{ config, ... }:

{
  # OIDC/Keycloak SSO secret — resolved at boot by `op inject`, never in the Nix store.
  # Creates an EnvironmentFile at /run/secrets/fleet/paperless-oidc containing
  # PAPERLESS_SOCIALACCOUNT_PROVIDERS with the Keycloak OIDC JSON config.
  fleet.secrets."paperless-oidc" = {
    template = ''
PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"OAUTH_PKCE_ENABLED":true,"APPS":[{"provider_id":"keycloak","name":"Keycloak","client_id":"{{ op://Fleet/Keycloak-Paperless/client-id }}","secret":"{{ op://Fleet/Keycloak-Paperless/client-secret }}","settings":{"server_url":"{{ op://Fleet/Keycloak-Paperless/server-url }}"}}]}}
    '';
    owner = "paperless";
    mode = "0400";
  };

  users.users.paperless = {
    isSystemUser = true;
    uid = 315;
    group = "paperless";
    description = "Paperless service user";
  };
  users.groups.paperless = { gid = 315; };

  services.postgresql.ensureDatabases = [ "paperless" ];
  services.postgresql.ensureUsers = [
    {
      name = "paperless";
      ensureDBOwnership = true;
    }
  ];

	services.cloudflared.tunnels."a0306444-7c05-4c03-9152-d6c09e116854".ingress = {
		"cabinet.analogrelay.net" = "http://localhost:28981";
	};

  services.paperless = {
    enable = true;

    # Directories on the NFS share
    dataDir        = "/mnt/tank/services/paperless/data";
    mediaDir       = "/mnt/tank/services/paperless/media";
    consumptionDir = "/mnt/tank/services/paperless/consume";

    # Load OIDC secrets (PAPERLESS_SOCIALACCOUNT_PROVIDERS) from fleet secret
    environmentFile = config.fleet.secrets."paperless-oidc".path;

    settings = {
      # Enable the OpenID Connect social account provider for Keycloak SSO
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_TRASH_DIR = "/mnt/tank/services/paperless/trash/";

      # Connect to postgres via unix socket using peer auth
      # (OS user "paperless" → postgres role "paperless")
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBHOST   = "/run/postgresql";
      PAPERLESS_DBNAME   = "paperless";
      PAPERLESS_DBUSER   = "paperless";

      # Point to our existing redis instance
      PAPERLESS_REDIS = "unix:///run/redis-paperless/redis.sock";

			PAPERLESS_URL = "https://cabinet.analogrelay.net";
    };
  };

  # The module's ProtectSystem=strict makes all paths read-only except those in
  # ReadWritePaths (dataDir, mediaDir, consumptionDir). PAPERLESS_TRASH_DIR is
  # not covered, so grant write access explicitly on every service unit.
  # Also ensure all services wait for fleet secrets to be provisioned.
  systemd.services.paperless-scheduler.serviceConfig.ReadWritePaths  = [ "/mnt/tank/services/paperless/trash" ];
  systemd.services.paperless-task-queue.serviceConfig.ReadWritePaths = [ "/mnt/tank/services/paperless/trash" ];
  systemd.services.paperless-consumer.serviceConfig.ReadWritePaths   = [ "/mnt/tank/services/paperless/trash" ];
  systemd.services.paperless-web.serviceConfig.ReadWritePaths        = [ "/mnt/tank/services/paperless/trash" ];

  systemd.services.paperless-web.after            = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-web.requires         = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-scheduler.after       = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-scheduler.requires    = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-task-queue.after      = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-task-queue.requires   = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-consumer.after        = [ "provision-fleet-secrets.service" ];
  systemd.services.paperless-consumer.requires     = [ "provision-fleet-secrets.service" ];

	services.fail2ban.jails.paperless.settings = {
		enabled  = true;
		maxretry = 5;
		filter   = "paperless";
		action   = "cloudflare-list";
		logpath  = "/mnt/tank/services/paperless/data/log/paperless.log";
		port     = "28981";
	};
	environment.etc."fail2ban/filter.d/paperless.local".text = 
		''
		[Definition]
		failregex = Login failed for user `.*` from (?:IP|private IP) `<HOST>`\.$
		ignoreregex =
		'';
}
