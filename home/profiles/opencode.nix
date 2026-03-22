{ pkgs, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  home.packages = [ pkgs.opencode ];
  home.file.".config/opencode/opencode.json".source =
    fleetLink "config/opencode/opencode.json";
  home.file.".config/opencode/agents".source =
    fleetLink "config/opencode/agents";
  home.file.".config/opencode/command".source =
    fleetLink "config/opencode/command";
}
