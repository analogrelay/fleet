let
  ashley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEPYNdw1bK/GpkOGZ5dULppRhjktpeKEm0GMPE/tg5fc";
  users = [ ashley ];

  systems = [ ];
in
{
  "k3s-token.age".publicKeys = users ++ systems;
}