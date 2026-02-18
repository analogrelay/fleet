{ config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  home.file.".config/retroarch/retroarch.cfg".source =
    fleetLink "config/retroarch/retroarch.cfg";
}