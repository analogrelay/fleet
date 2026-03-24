{ ... }:

{
  # Linux system user — matches the Postgres role name for peer auth
  users.users.paperless = {
    isSystemUser = true;
    uid = 315;
    group = "paperless";
    description = "Paperless service user";
  };
  users.groups.paperless = { gid = 315; };

  # Postgres role + database (merged into the list from homedb.nix — no conflict)
  services.postgresql.ensureDatabases = [ "paperless" ];
  services.postgresql.ensureUsers = [
    {
      name = "paperless";
      ensureDBOwnership = true;   # ALTER DATABASE paperless OWNER TO paperless
    }
  ];

	services.cloudflared.tunnels."00000000-0000-0000-0000-000000000000".ingress = {
		"cabinet.analogrelay.net" = "http://localhost:28981";
	};

  services.paperless = {
    enable = true;

    # Directories on the NFS share
    dataDir        = "/mnt/tank/services/paperless/data";
    mediaDir       = "/mnt/tank/services/paperless/media";
    consumptionDir = "/mnt/tank/services/paperless/consume";

    settings = {
      PAPERLESS_TRASH_DIR = "/mnt/tank/services/paperless/trash/";

      # Connect to postgres via unix socket using peer auth
      # (OS user "paperless" → postgres role "paperless")
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBHOST   = "/run/postgresql";
      PAPERLESS_DBNAME   = "paperless";
      PAPERLESS_DBUSER   = "paperless";

      # Point to our existing redis instance
      PAPERLESS_REDIS = "unix:///run/redis-paperless/redis.sock";

			PAPERLESS_URL = "https://cabinet.analogrelay.net";
    };
  };

  # The module's ProtectSystem=strict makes all paths read-only except those in
  # ReadWritePaths (dataDir, mediaDir, consumptionDir). PAPERLESS_TRASH_DIR is
  # not covered, so grant write access explicitly on every service unit.
  systemd.services.paperless-scheduler.serviceConfig.ReadWritePaths  = [ "/mnt/tank/services/paperless/trash" ];
  systemd.services.paperless-task-queue.serviceConfig.ReadWritePaths = [ "/mnt/tank/services/paperless/trash" ];
  systemd.services.paperless-consumer.serviceConfig.ReadWritePaths   = [ "/mnt/tank/services/paperless/trash" ];
  systemd.services.paperless-web.serviceConfig.ReadWritePaths        = [ "/mnt/tank/services/paperless/trash" ];
}
