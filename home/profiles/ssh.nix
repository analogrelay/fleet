{ config, ... }:

let
  fleetLink =
    path: config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in
{
  home.file = {
    ".ssh/config".source = fleetLink "config/ssh/config";
    ".ssh/github-msft.pub".source = fleetLink "keys/github-msft.pub";
  };
}
