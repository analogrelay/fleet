{ pkgs, config, ... }:

{
  services.nzbget = {
    enable = true;
    settings = {
      MainDir = "/var/lib/nzbget/config";
      DestDir = "/mnt/tank/downloads/nzbget";
    };
  };
  networking.firewall.allowedTCPPorts = [ 6789 ];

  users.users.radarr.extraGroups = [ "share" ];

  services.jackett = {
    enable = true;
    openFirewall = true;
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = 7880;
    torrentingPort = 7881;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    settings = {
      auth.method = "external";
      server = {
        urlbase = "localhost";
        port = 7878;
        bindaddress = "*";
      };
    };
  };

  services.caddy.virtualHosts."radarr.analogrelay.net" = {
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
      route {
        # always forward outpost path to actual outpost
        reverse_proxy /outpost.goauthentik.io/* http://127.0.0.1:9000

        # forward authentication to outpost
        forward_auth http://127.0.0.1:9000 {
            uri /outpost.goauthentik.io/auth/caddy

            # capitalization of the headers is important, otherwise they will be empty
            copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Entitlements X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version

            # optional, in this config trust all private ranges, should probably be set to the outposts IP
            trusted_proxies private_ranges
        }

        # actual site configuration below, for example
        reverse_proxy localhost:7878
      }
    '';
  };
}
