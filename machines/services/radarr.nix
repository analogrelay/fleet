{ pkgs, config, ... }:

{
	fleet.secrets."oauth2-radarr.env" = {
		template = 
			''
			OAUTH2_PROXY_CLIENT_SECRET={{ op://Fleet/Keycloak-Radarr/client-secret }}
			OAUTH2_PROXY_COOKIE_SECRET={{ op://Fleet/Keycloak-Radarr/cookie-secret }}
			'';
		owner = "oauth2-proxy";
		group = "oauth2-proxy";
    mode = "0400";
	};

	services.nzbget = {
		enable = true;
		settings = {
			MainDir = "/var/lib/nzbget/config";
			DestDir = "/mnt/tank/downloads/nzbget";
		};
	};
  networking.firewall.allowedTCPPorts = [ 6789 ];

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

	systemd.services."oauth2-radarr" = 
	let
		configString = pkgs.lib.strings.concatStringsSep " " [
			"--http-address=127.0.0.1:7879"
			"--provider=keycloak-oidc"
			"--client-id=radarr"
			"--cookie-domain=radarr.analogrelay.net"
			"--redirect-url=https://radarr.analogrelay.net/oauth2/callback"
			"--email-domain=*"
			"--oidc-issuer-url=https://id.analogrelay.net/realms/analoghome"
			"--code-challenge-method=S256"
		];
	in {
		description = "OAuth2 Proxy (Radarr)";
		path = [ pkgs.oauth2-proxy ];
		wantedBy = [ "multi-user.target" ];
		wants = [ "network-online.target" "keycloak.service" "provision-fleet-secrets.service" ];
		after = [ "network-online.target" "keycloak.service" "provision-fleet-secrets.service" ];
		serviceConfig = {
			User = "oauth2-proxy";
			Restart = "always";
			ExecStart = "${pkgs.lib.getExe pkgs.oauth2-proxy} ${configString}";
			EnvironmentFile = config.fleet.secrets."oauth2-radarr.env".path;
		};
	};

	services.caddy.virtualHosts."http://radarr.analogrelay.net" = {
		extraConfig = 
		''
			handle /oauth2/* {
				reverse_proxy localhost:7879 {
					header_up X-Real-IP {remote_host}
					header_up X-Forwarded-Uri {uri}
				}
			}
			handle {
				forward_auth localhost:7879 {
					uri /oauth2/auth
					header_up X-Real-IP {remote_host}

					@error status 401
					handle_response @error {
						redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
					}
				}
				reverse_proxy :7878
			}
		'';
	};

	services.cloudflared.tunnels."a0306444-7c05-4c03-9152-d6c09e116854".ingress = {
		"radarr.analogrelay.net" = "http://localhost";
	};
}
