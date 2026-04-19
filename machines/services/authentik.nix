{ config, ... }:

{
  services.postgresql.ensureDatabases = [ "authentik" ];
  services.postgresql.ensureUsers = [
    {
      name = "authentik";
      ensureDBOwnership = true;
    }
  ];

  fleet.secrets."authentik.env" = {
    template = ''
      AUTHENTIK_SECRET_KEY={{ op://Fleet/Authentik/secret-key }}
    '';
    owner = "authentik";
    group = "authentik";
    mode = "0400";
  };
  systemd.services.authentik.after = [ "provision-fleet-secrets.service" ];
  systemd.services.authentik.requires = [ "provision-fleet-secrets.service" ];
  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
  };
  users.groups.authentik = {};
  services.authentik = {
    enable = true;
    environmentFile = config.fleet.secrets."authentik.env".path;
    settings = {
      postgres = {
        host = "/run/postgresql/";
        user = "authentik";
      };
      storage.file.path = "/var/lib/authentik/";
      listen = {
        http = "127.0.0.1:9000";
        https = "127.0.0.1:9443";
      };
    };
  };
  services.caddy.virtualHosts."auth.analogrelay.net" = {
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
      reverse_proxy 127.0.0.1:9000
    '';
  };
}
