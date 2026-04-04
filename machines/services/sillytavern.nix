{ pkgs, config, ... }:

{
  services.sillytavern = {
    enable = true;
    port = 50505;
  };

  fleet.secrets."oauth2-sillytavern.env" = {
    template = 
      ''
      OAUTH2_PROXY_CLIENT_SECRET={{ op://Fleet/Keycloak-SillyTavern/client-secret }}
      OAUTH2_PROXY_COOKIE_SECRET={{ op://Fleet/Keycloak-SillyTavern/cookie-secret }}
      '';
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    mode = "0400";
  };

  systemd.services."oauth2-sillytavern" = 
  let
    configString = pkgs.lib.strings.concatStringsSep " " [
      "--http-address=127.0.0.1:50506"
      "--provider=keycloak-oidc"
      "--client-id=sillytavern"
      "--cookie-domain=tavern.analogrelay.net"
      "--redirect-url=https://tavern.analogrelay.net/oauth2/callback"
      "--email-domain=*"
      "--oidc-issuer-url=https://id.analogrelay.net/realms/analoghome"
      "--code-challenge-method=S256"
    ];
  in {
    description = "OAuth2 Proxy (SillyTavern)";
    path = [ pkgs.oauth2-proxy ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" "keycloak.service" "provision-fleet-secrets.service" ];
    after = [ "network-online.target" "keycloak.service" "provision-fleet-secrets.service" ];
    serviceConfig = {
      User = "oauth2-proxy";
      Restart = "always";
      ExecStart = "${pkgs.lib.getExe pkgs.oauth2-proxy} ${configString}";
      EnvironmentFile = config.fleet.secrets."oauth2-sillytavern.env".path;
    };
  };

  services.caddy.virtualHosts."http://tavern.analogrelay.net" = {
    extraConfig = 
    ''
      handle /oauth2/* {
        reverse_proxy localhost:50506 {
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-Uri {uri}
        }
      }
      handle {
        forward_auth localhost:50506 {
          uri /oauth2/auth
          header_up X-Real-IP {remote_host}

          @error status 401
          handle_response @error {
            redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
          }
        }
        reverse_proxy :50505
      }
    '';
  };

  services.cloudflared.tunnels."a0306444-7c05-4c03-9152-d6c09e116854".ingress = {
    "tavern.analogrelay.net" = "http://localhost";
  };
}
