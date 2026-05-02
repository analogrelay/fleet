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

  # --- Restore test scripts ---
  systemd.services.postgres-test-restore = {
    description = "Manual Postgres WAL-G test restore";
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
      RemainAfterExit = false;
    };
    
    script = ''
      set -e
      
      export PGDATA=/var/lib/postgresql/test-restore
      export WALGC_FILE_PREFIX=/mnt/tank/backups/postgres
      
      mkdir -p $PGDATA
      chmod 700 $PGDATA
      
      echo "Fetching latest WAL-G backup..."
      ${pkgs.wal-g}/bin/wal-g backup-fetch $PGDATA LATEST
      
      touch $PGDATA/recovery.signal
      
      echo "Starting Postgres on port 5433..."
      ${config.services.postgresql.package}/bin/pg_ctl \
        -D $PGDATA \
        -l /var/log/postgresql/test-restore.log \
        -o "-p 5433" \
        start
      
      echo "Test restore started. Connect with: psql -h localhost -p 5433"
      echo "Stop with: systemctl stop postgres-test-restore"
    '';
    
    preStop = ''
      echo "Stopping test restore cluster..."
      ${config.services.postgresql.package}/bin/pg_ctl \
        -D /var/lib/postgresql/test-restore \
        -m fast stop || true
    '';
    
    postStop = ''
      echo "Removing test data directory..."
      rm -rf /var/lib/postgresql/test-restore
    '';
  };

  systemd.services.postgres-test-restore-cleanup = {
    description = "Clean up Postgres test restore";
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
    };
    script = ''
      ${config.services.postgresql.package}/bin/pg_ctl \
        -D /var/lib/postgresql/test-restore \
        -m fast stop || true
      rm -rf /var/lib/postgresql/test-restore
    '';
  };
}
