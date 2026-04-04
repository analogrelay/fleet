{ config, pkgs, ... }:

let
  postgresUsername = config.fleet.secrets."postgres-admin-username".path;
  postgresPassword = config.fleet.secrets."postgres-admin-password".path;
  alloyPassword = config.fleet.secrets."postgres-alloy-password".path;
in
{
  fleet.secrets."postgres-admin-username" = {
    source = "op://Fleet/PostgresAdmin/username";
    owner = "postgres";
  };
  fleet.secrets."postgres-admin-password" = {
    source = "op://Fleet/PostgresAdmin/password";
    owner = "postgres";
  };
  fleet.secrets."postgres-alloy-password" = {
    template = "PG_ALLOY_PASS={{op://Fleet/PostgresAlloy/password}}";
    owner = "postgres";
  };

  systemd.services.postgresql.after = [ "provision-fleet-secrets.service" ];
  systemd.services.postgresql.requires = [ "provision-fleet-secrets.service" ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [ "fleet" ];
    ensureUsers = [
      {
        name = "fleet";
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
      {
        name = "alloy";
        ensureClauses.login = true;
      }
    ];

    # Maps root → postgres role; all other OS users → same-named PG role
    identMap = ''
      peer_map root     postgres
      peer_map /^(.*)$  \1
    '';
    settings.listen_addresses = pkgs.lib.mkForce "*";

    # Unix socket: peer auth with ident map (Linux username = postgres role name)
    # TCP loopback + LAN + Tailnet: password auth (scram-sha-256)
    authentication = pkgs.lib.mkOverride 10 ''
      local all all              peer map=peer_map
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
      host  all all 192.168.0.0/16 scram-sha-256
      host  all all 100.64.0.0/10  scram-sha-256
    '';
  };

  # Configure the admin user and password at runtime using secret files
  systemd.services.postgresql-fleet-setup = {
    description = "Configure PostgreSQL fleet admin user";
    after = [ "postgresql.service" "provision-fleet-secrets.service" ];
    requires = [ "postgresql.service" "provision-fleet-secrets.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };

    script = ''
      PG_USER="$(cat ${postgresUsername})"
      PG_PASS="$(cat ${postgresPassword})"
      . ${alloyPassword}

      # Create user if it doesn't exist, then set password
      ${config.services.postgresql.package}/bin/psql -tAc \
        "SELECT 1 FROM pg_roles WHERE rolname = '$PG_USER'" | grep -q 1 || \
        ${config.services.postgresql.package}/bin/psql -c \
          "CREATE ROLE \"$PG_USER\" WITH LOGIN SUPERUSER;"

      # Create user if it doesn't exist, then set password
      ${config.services.postgresql.package}/bin/psql -tAc \
        "SELECT 1 FROM pg_roles WHERE rolname = 'alloy'" | grep -q 1 || \
        ${config.services.postgresql.package}/bin/psql -c \
          "CREATE ROLE \"alloy\" WITH LOGIN SUPERUSER;"

      ${config.services.postgresql.package}/bin/psql -c \
        "ALTER ROLE \"alloy\" WITH PASSWORD '$PG_ALLOY_PASS';"

      # Create database if it doesn't exist
      ${config.services.postgresql.package}/bin/psql -tAc \
        "SELECT 1 FROM pg_database WHERE datname = '$PG_USER'" | grep -q 1 || \
        ${config.services.postgresql.package}/bin/createdb -O "$PG_USER" "$PG_USER"

      # Grant pg_monitor to alloy user
      ${config.services.postgresql.package}/bin/psql -c \
        "GRANT pg_monitor TO alloy;"
    '';
  };

  systemd.services.alloy.serviceConfig.EnvironmentFile = [ alloyPassword ];

  # Only allow PostgreSQL from the LAN; tailnet is already trusted via tailscale0
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -s 192.168.0.0/16 -p tcp --dport 5432 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 192.168.0.0/16 -p tcp --dport 5432 -j nixos-fw-accept 2>/dev/null || true
  '';
}
