{ pkgs, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  home.packages = [ pkgs.jujutsu ];
  home.file.".config/jj/config.toml".source = fleetLink "config/jj/config.toml";
}
