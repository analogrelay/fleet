{ lib, platform, ... }:

{
  imports = [
  ] ++ (lib.optional (builtins.pathExists ./analoghome.${platform}.nix) ./analoghome.${platform}.nix);

  home-manager.extraSpecialArgs = {
    realm = "analoghome";
  };
}
