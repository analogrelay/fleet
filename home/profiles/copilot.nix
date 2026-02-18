{ pkgs, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  home.file.".config/copilot".source = fleetLink "config/copilot";
}
