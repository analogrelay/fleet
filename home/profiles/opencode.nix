{ pkgs, config, ... }:
let
  fleetLink = path: config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in
{
  home.packages = [ pkgs.opencode ];
  home.file.".config/opencode/opencode.jsonc".source = fleetLink "config/opencode/opencode.jsonc";
  home.file.".config/opencode/agents".source = fleetLink "config/opencode/agents";
  home.file.".config/opencode/code-review".source = fleetLink "config/opencode/code-review";
}
