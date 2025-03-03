{ pkgs, lib, platform, wsl, ... }:

{
  imports = [
  ] ++ (lib.optional (builtins.pathExists ./workstation.${platform}.nix) ./workstation.${platform}.nix);

  home-manager.extraSpecialArgs = {
    role = "workstation";
  };
}
