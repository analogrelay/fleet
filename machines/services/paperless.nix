{ config, pkgs-unstable, ... }:

{
  # OIDC/Keycloak SSO secret — resolved at boot by `op inject`, never in the Nix store.
  # Creates an EnvironmentFile at /run/secrets/fleet/paperless-oidc containing
  # PAPERLESS_SOCIALACCOUNT_PROVIDERS with the Keycloak OIDC JSON config.
  fleet.secrets."paperless-oidc" = {
    template = ''
PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"OAUTH_PKCE_ENABLED":true,"APPS":[{"provider_id":"authentik","name":"AnalogHome","client_id":"{{ op://Fleet/OAuth-Paperless/client-id }}","secret":"{{ op://Fleet/OAuth-Paperless/client-secret }}","settings":{"server_url":"{{ op://Fleet/OAuth-Paperless/server-url }}"}}]}}
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

  services.paperless = {
    enable = true;
    package = pkgs-unstable.paperless-ngx;
    address = "0.0.0.0";

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
  networking.firewall.allowedTCPPorts = [ 28981 ];

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

  services.caddy.virtualHosts."cabinet.analogrelay.net" = {
    extraConfig = ''
      tls { 
        dns azure {
          subscription_id {$AZURE_SUBSCRIPTION_ID}
          resource_group_name {$AZURE_RESOURCE_GROUP_NAME}
          tenant_id {$AZURE_TENANT_ID}
          client_id {$AZURE_CLIENT_ID}
          client_secret {$AZURE_CLIENT_SECRET}
        }
      }
      reverse_proxy 127.0.0.1:28981
    '';
  };
}
