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
        routers = {
					traefik = {
					  rule = "(Host(`avalanche.analogno.de`) || Host(`avalanche.bicorn-bebop.ts.net`)) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
						entryPoints = [ "web" ];
						service = "api@internal";
					};
					root-redirect = {
					  rule = "(Host(`avalanche.analogno.de`) || Host(`avalanche.bicorn-bebop.ts.net`)) && Path(`/`)";
						entryPoints = [ "web" ];
						middlewares = [ "redirect-to-dashboard" ];
						service = "api@internal"; # needs a service even though it'll redirect
					};
				};
				middlewares = {
					redirect-to-dashboard = {
					  redirectRegex = {
							regex = "^http://([^/]+)/$";
							replacement = "http://$1/dashboard/";
							permanent = false;
						};
					};
				};
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
