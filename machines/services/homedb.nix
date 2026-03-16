{ pkgs, secrets, ... }:

{
  services.postgresql = {
    enable = true;
    ensureDatabases = [ 
			secrets.PostgresAdmin.username
		];
    ensureUsers = [
      {
        name = secrets.PostgresAdmin.username;
        ensureDBOwnership = true;
      }
    ];
    # Sets the password on first DB initialization only
    initialScript = pkgs.writeText "homedb-init" ''
      ALTER USER "${secrets.PostgresAdmin.username}" WITH PASSWORD '${secrets.PostgresAdmin.password}';
    '';
    # Unix socket: peer auth (Linux username = postgres role name)
    # TCP loopback: password auth (scram-sha-256)
    authentication = pkgs.lib.mkOverride 10 ''
      local all all              peer
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5432 ];
}
