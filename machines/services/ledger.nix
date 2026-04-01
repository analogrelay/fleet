{ config, ... }:

{
  fleet.secrets."postgres-ledger-password" = {
    source = "op://Fleet/PostgresLedger/password";
    owner = "postgres";
  };

  users.users.ledger = {
    isSystemUser = true;
    group = "ledger";
    description = "Ledger service user";
  };
  users.groups.ledger = {};

  services.postgresql.ensureDatabases = [ "ledger" ];
  services.postgresql.ensureUsers = [
    {
      name = "ledger";
      ensureDBOwnership = true;
    }
  ];

  systemd.services.postgresql-ledger-setup = {
    description = "Configure PostgreSQL ledger user";
    after = [ "postgresql.service" "provision-fleet-secrets.service" ];
    requires = [ "postgresql.service" "provision-fleet-secrets.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };

    script = ''
      PG_USER="ledger"
      PG_PASS="$(cat ${config.fleet.secrets."postgres-ledger-password".path})"

      ${config.services.postgresql.package}/bin/psql -c \
        "ALTER ROLE \"$PG_USER\" WITH PASSWORD '$PG_PASS';"
    '';
  };
}
