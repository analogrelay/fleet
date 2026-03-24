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

  services.paperless = {
    enable = true;

    # Directories on the NFS share
    dataDir        = "/mnt/avalanche/shares/public/cabinet/data";
    mediaDir       = "/mnt/avalanche/shares/public/cabinet/media";
    consumptionDir = "/mnt/avalanche/shares/public/cabinet/consume";

    settings = {
      PAPERLESS_TRASH_DIR = "/mnt/avalanche/shares/public/cabinet/trash";

      # Connect to postgres via unix socket using peer auth
      # (OS user "paperless" → postgres role "paperless")
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBHOST   = "/run/postgresql";
      PAPERLESS_DBNAME   = "paperless";
      PAPERLESS_DBUSER   = "paperless";

      # Point to our existing redis instance
      PAPERLESS_REDIS = "unix:///run/redis-paperless/redis.sock";

      PAPERLESS_ALLOWED_HOSTS = "cabinet.bicorn-bebop.ts.net,cabinet.analogrelay.net,shinra.bicorn-bebop.ts.net";
      PAPERLESS_CORS_TRUSTED_ORIGINS = "https://cabinet.bicorn-bebop.ts.net,https://cabinet.analogrelay.net,https://shinra.bicorn-bebop.ts.net";
      PAPERLESS_CORS_ALLOWED_HOSTS = "https://cabinet.bicorn-bebop.ts.net,https://cabinet.analogrelay.net,https://shinra.bicorn-bebop.ts.net";
    };
  };

  # The module's ProtectSystem=strict makes all paths read-only except those in
  # ReadWritePaths (dataDir, mediaDir, consumptionDir). PAPERLESS_TRASH_DIR is
  # not covered, so grant write access explicitly on every service unit.
  systemd.services.paperless-scheduler.serviceConfig.ReadWritePaths  = [ "/mnt/avalanche/shares/public/cabinet/trash" ];
  systemd.services.paperless-task-queue.serviceConfig.ReadWritePaths = [ "/mnt/avalanche/shares/public/cabinet/trash" ];
  systemd.services.paperless-consumer.serviceConfig.ReadWritePaths   = [ "/mnt/avalanche/shares/public/cabinet/trash" ];
  systemd.services.paperless-web.serviceConfig.ReadWritePaths        = [ "/mnt/avalanche/shares/public/cabinet/trash" ];
}
