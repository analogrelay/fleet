{ config, ... }:

{
  services.grafana = {
    enable = true;
    settings = {
      "auth.basic".enabled = false;
      "auth.generic_oauth" = {
        enabled = true;
        auto_login = true;
        use_pkce = true;
        name = "Keycloak-OAuth";
        allow_sign_up = true;
        scopes = "openid email profile offline_access roles";
        email_attribute_path = "email";
        login_attribute_path = "username";
        name_attribute_path = "full_name";
        auth_url = "https://id.analogrelay.net/realms/analoghome/protocol/openid-connect/auth";
        token_url = "https://id.analogrelay.net/realms/analoghome/protocol/openid-connect/token";
        role_attribute_path = "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'";
      };
      server = {
        protocol = "http";
        port = "3000";
        http_addr = "0.0.0.0";
        domain = "grafana.analogrelay.net";
        root_url = "https://grafana.analogrelay.net";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 3000 ];

  fleet.secrets."grafana-oidc" = {
    template = ''
      GF_AUTH_GENERIC_OAUTH_CLIENT_ID={{ op://Fleet/Keycloak-Grafana/client-id }}
      GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET={{ op://Fleet/Keycloak-Grafana/client-secret }}
    '';
    owner = "grafana";
    mode = "0400";
  };

  systemd.services.grafana = {
    after = [ "provision-fleet-secrets.service" ];
    requires = [ "provision-fleet-secrets.service" ];
    serviceConfig.EnvironmentFile = config.fleet.secrets."grafana-oidc".path;
  };
}
