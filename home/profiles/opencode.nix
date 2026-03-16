{ pkgs, config, ... }:
let
  fleetLink = path: config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in
{
  home.packages = [ pkgs.opencode ];
  home.file.".config/opencode/opencode.jsonc".source = fleetLink "config/opencode/opencode.jsonc";
}
