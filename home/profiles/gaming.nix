{ config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  home.file.".config/retroarch/retroarch.cfg".source =
    fleetLink "home/profiles/retroarch.cfg";
}