{ lib, platform, ... }:

{
    imports = [
    ] ++ lib.optional (builtins.pathExists ./microsoft.${platform}.nix) ./microsoft.${platform.nix};
}