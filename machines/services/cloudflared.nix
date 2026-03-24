{ config, ... }:

{
  fleet.secrets."cloudflared-tunnel-creds" = {
    source = "op://Fleet/Cloudflare/tunnel-creds";
  };
	fleet.secrets."cloudflared-tunnel-cert.pem" = {
		source = "op://Fleet/Cloudflare/tunnel-cert.pem";
	};
	services.cloudflared = {
		enable = true;
		certificateFile = config.fleet.secrets."cloudflared-tunnel-cert.pem".path;
		tunnels."a0306444-7c05-4c03-9152-d6c09e116854" = {
			credentialsFile = config.fleet.secrets."cloudflared-tunnel-creds".path;
			default = "http_status:404";
		};
	};
	systemd.services."cloudflared-tunnel-a0306444-7c05-4c03-9152-d6c09e116854.service".after = [
		"provision-fleet-secrets.service"
	];
}
