{ pkgs, config, ... }:

{
  services.sillytavern = {
    enable = true;
    whitelist = false;
  };
  
  # The sillytavern `listen` arg is broken
  systemd.services.sillytavern.serviceConfig.ExecStart = pkgs.lib.mkForce
    "${pkgs.lib.getExe pkgs.sillytavern} --port 50505 --listen";
  systemd.tmpfiles.settings.sillytavern."/var/lib/SillyTavern/config.yaml" = pkgs.lib.mkForce {};
  networking.firewall.allowedTCPPorts = [ 50505 ];

  services.caddy.virtualHosts."tavern.analogrelay.net" = {
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
        reverse_proxy localhost:50505
      }
    '';
  };
}
