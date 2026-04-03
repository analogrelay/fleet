{ config, pkgs, ... }:

let
  backupDir = "/mnt/tank/backups/postgres";
  walG = pkgs.wal-g;

  # Wrapper for archive_command — PostgreSQL calls this for each WAL segment.
  # Needs explicit env vars since PG executes it in a restricted environment.
  archiveCommand = pkgs.writeShellScript "wal-g-archive" ''
    export WALG_FILE_PREFIX="${backupDir}"
    export WALG_COMPRESSION_METHOD="zstd"
    ${walG}/bin/wal-g wal-push "$1"
  '';

  walGEnv = [
    "WALG_FILE_PREFIX=${backupDir}"
    "PGHOST=/run/postgresql"
    "WALG_COMPRESSION_METHOD=zstd"
  ];
in
{
  # --- PostgreSQL WAL archival settings ---
  services.postgresql.settings = {
    archive_mode = "on";
    archive_command = "${archiveCommand} %p";
    archive_timeout = 60;
  };

  # --- Ensure backup directory exists with correct ownership ---
  systemd.tmpfiles.rules = [
    "d ${backupDir} 0750 postgres postgres -"
  ];

  # --- Full base backup service ---
  systemd.services.wal-g-backup = {
    description = "WAL-G PostgreSQL full base backup";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Environment = walGEnv;
      ExecStart = "${walG}/bin/wal-g backup-push ${config.services.postgresql.dataDir}";
    };
  };

  # --- Daily timer for full backups ---
  systemd.timers.wal-g-backup = {
    description = "Daily WAL-G full base backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # --- Retention cleanup service ---
  systemd.services.wal-g-backup-cleanup = {
    description = "WAL-G PostgreSQL backup retention cleanup";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Environment = walGEnv;
      ExecStart = "${walG}/bin/wal-g delete --retain-full 7 --confirm";
    };
  };

  # --- Weekly timer for retention cleanup ---
  systemd.timers.wal-g-backup-cleanup = {
    description = "Weekly WAL-G backup retention cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 04:00:00";
      Persistent = true;
    };
  };
}
