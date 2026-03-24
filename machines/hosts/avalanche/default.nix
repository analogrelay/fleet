{ pkgs, config, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../profiles/tailnet.nix

			../../services/postgres.nix
			../../services/redis.nix
			../../services/paperless.nix
    ];

  networking.hostName = "avalanche";

  # Enable linger so systemd user services (e.g. fleet-sync timer) run
  # without an active login session.
  users.users.ashley.linger = true;
  networking.hostId = "19cc4826";

  system.stateVersion = "25.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_1.gasket
    zfs
  ];

	services.samba = {
		enable = true;
		openFirewall = true;
		settings = {
			global = {
				workgroup = "GAIA";
				"server string" = config.networking.hostName;
				"netbios name" = config.networking.hostName;
				security = "user";
				"guest account" = "nobody";
			};
			homes = {
				path = "/mnt/tank/homes/%S";
				browsable = true;
				"read only" = false;
				"create mask" = "0700";
				"directory mask" = "0700";
			};
			public = {
				path = "/mnt/tank/shares/public";
				browsable = true;
				"read only" = false;
				"create mask" = "0775";
				"directory mask" = "0775";
				"force user" = "share";
				"force group" = "share";
			};
		};
	};
}

