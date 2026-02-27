{ ... }:

{
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      api.dashboard = true;
      entryPoints.web.address = ":80";
    };
    dynamicConfigOptions = {
      http = {
        routers.traefik = {
          rule = "PathPrefix(`/api`) || PathPrefix(`/dashboard`)";
          entryPoints = [ "web" ];
          service = "api@internal";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
