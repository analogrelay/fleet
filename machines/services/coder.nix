{ pkgs, config, ... }:

{
  fleet.secrets."coder-oidc" = {
    template = ''
      CODER_OIDC_CLIENT_ID="{{ op://Fleet/Keycloak-Coder/client-id }}"
      CODER_OIDC_CLIENT_SECRET="{{ op://Fleet/Keycloak-Coder/client-secret }}"
    '';
    owner = "coder";
    mode = "0400";
  };

  services.coder = {
    enable = true;
    accessUrl = "https://coder.analogrelay.net";
    listenAddress = "0.0.0.0:9393";
    database.createLocally = true;
    environment = {
      extra = {
        CODER_WILDCARD_ACCESS_URL = "*.coder.analogrelay.net";
        CODER_HTTP_ADDRESS = "0.0.0.0:9393";
        CODER_DISABLE_PASSWORD_AUTH = "true";
        CODER_OIDC_ISSUER_URL = "https://id.analogrelay.net/realms/analoghome";
      };
      file = config.fleet.secrets."coder-oidc".path;
    };
  };
  networking.firewall.allowedTCPPorts = [ 9393 ];

  systemd.services.coder = {
    after = [ "provision-fleet-secrets.service" ];
    wants = [ "provision-fleet-secrets.service" ];
    serviceConfig = {
      SupplementaryGroups = [ "docker" ];
    };
  };

  environment.systemPackages = [ pkgs.coder ];
}
