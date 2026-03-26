{ ... }:

{
	services.caddy = {
		enable = true;
		globalConfig = 
			''
			auto_https off
			'';
	};
}
