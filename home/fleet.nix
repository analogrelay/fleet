{ config, lib, ... }:

{
  options.fleet.repoDir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.config/fleet";
    description = "Absolute path to the fleet repository checkout.";
  };
}
