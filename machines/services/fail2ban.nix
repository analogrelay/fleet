{ pkgs, ... }:

{
	services.fail2ban = {
		enable = true;
	};

	environment.systemPackages = [
		pkgs.fail2ban
	];
}
