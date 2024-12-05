{ lib, platform, ... }:

{
    #imports = [
    #] ++ lib.optional (builtins.pathExists ./analoghome.${platform}.nix) ./analoghome.${platform.nix};
}
