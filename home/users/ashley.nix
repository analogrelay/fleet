{ realm, ... }:
{
    home.file.".ssh/authorized_keys".text = if realm == "analoghome" then ''
      ${builtins.readFile ../../keys/local-server-admin.pub}
    '' else ''
    '';
}