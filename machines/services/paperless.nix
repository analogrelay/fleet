{ ... }:

{
  # Linux system user — matches the Postgres role name for peer auth
  users.users.paperless = {
    isSystemUser = true;
    group = "paperless";
    description = "Paperless service user";
  };
  users.groups.paperless = {};

  # Postgres role + database (merged into the list from homedb.nix — no conflict)
  services.postgresql.ensureDatabases = [ "paperless" ];
  services.postgresql.ensureUsers = [
    {
      name = "paperless";
      ensureDBOwnership = true;   # ALTER DATABASE paperless OWNER TO paperless
    }
  ];
}
