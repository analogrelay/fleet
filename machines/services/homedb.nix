{ pkgs, secrets, ... }:

{
  services.postgresql = {
    enable = true;
		package = pkgs.postgresql_16;
    ensureDatabases = [ 
			secrets.PostgresAdmin.username
		];
    ensureUsers = [
      {
        name = secrets.PostgresAdmin.username;
        ensureDBOwnership = true;
        ensureClauses.superuser = true;
      }
    ];
    # Sets the password on first DB initialization only
    initialScript = pkgs.writeText "homedb-init" ''
      ALTER USER "${secrets.PostgresAdmin.username}" WITH PASSWORD '${secrets.PostgresAdmin.password}';
    '';
    # Maps root → postgres role; all other OS users → same-named PG role
    identMap = ''
      peer_map root     postgres
      peer_map /^(.*)$  \1
    '';
    # Unix socket: peer auth with ident map (Linux username = postgres role name)
    # TCP loopback: password auth (scram-sha-256)
    authentication = pkgs.lib.mkOverride 10 ''
      local all all              peer map=peer_map
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5432 ];
}
