{ ... }:

{
	services.prometheus = {
		enable = true;
		retentionTime = "14d";
		port = 9090;
		extraFlags = [
			"--web.enable-remote-write-receiver"
		];
	};
  networking.firewall.allowedTCPPorts = [ 9090 ];
	
}
