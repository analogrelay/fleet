{ pkgs, config, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../profiles/tailnet.nix

      ../../services/authentik.nix
      ../../services/postgres.nix
      ../../services/redis.nix
      ../../services/wal-g.nix
      ../../services/syncthing.nix
      ../../services/speedtesting.nix
      ../../services/paperless.nix
      ../../services/sillytavern.nix
      ../../services/radarr.nix
      ../../services/jellyfin.nix
      ../../services/coder.nix
      ../../services/fail2ban.nix
      ../../services/ledger.nix
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
    rclone
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

  services.alloy.enable = true;
  systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];
  systemd.services.alloy.serviceConfig.AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
  environment.etc."alloy/config.alloy".source = ./config.alloy;

  # Give avalanche a stable port for more durable tailscale connections
  services.tailscale.port = 41641;
  networking.firewall.allowedUDPPorts = [ 41641 ];

  # Set up caddy as the central front door
  fleet.secrets."caddy.env" = {
    template = ''
      AZURE_TENANT_ID={{ op://Fleet/Azure-CaddyAvalanche/tenant-id }}
      AZURE_SUBSCRIPTION_ID={{ op://Fleet/Azure-CaddyAvalanche/subscription-id }}
      AZURE_RESOURCE_GROUP_NAME={{ op://Fleet/Azure-CaddyAvalanche/resource-group-name }}
      AZURE_CLIENT_ID={{ op://Fleet/Azure-CaddyAvalanche/client-id }}
      AZURE_CLIENT_SECRET={{ op://Fleet/Azure-CaddyAvalanche/client-secret }}
    '';
    owner = "caddy";
    mode = "0400";
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/azure@v0.6.0" ];
      hash = "sha256-B+X41GYIMoALfeVy2rjwK0zFC7nKbx3DKv4868v6hoQ=";
    };
    environmentFile = config.fleet.secrets."caddy.env".path;
    email = "contact@analogrelay.net";
    globalConfig = ''
      metrics
      acme_dns azure {
        subscription_id {$AZURE_SUBSCRIPTION_ID}
        resource_group_name {$AZURE_RESOURCE_GROUP_NAME}
        tenant_id {$AZURE_TENANT_ID}
        client_id {$AZURE_CLIENT_ID}
        client_secret {$AZURE_CLIENT_SECRET}
      }
    '';
    virtualHosts = {
      "avalanche.analogno.de" = {
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
          root /var/www
          file_server
        '';
      };
      "grafana.analogrelay.net" = {
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
          reverse_proxy http://shinra.analogno.de:3000
        '';
      };
    };
  };
}

