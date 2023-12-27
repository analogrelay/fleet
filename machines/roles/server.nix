{ platform, ... }:

{
  imports = [
    ./server.${platform}.nix
  ];

  home-manager.extraSpecialArgs = {
    role = "server";
  };
}