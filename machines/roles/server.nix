{ platform, lib, ... }:

{
  imports = [
  ] ++ lib.optional (builtins.pathExists ./server.${platform}.nix) ./server.${platform.nix};

  home-manager.extraSpecialArgs = {
    role = "server";
  };
}