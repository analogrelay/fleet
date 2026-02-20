{ config, lib, pkgs, ... }:

let
  adminHome = config.users.users.${config.fleet.admin}.home;
  fleetRoot = "${adminHome}/.config/fleet";
in
{
  options.fleet.admin = lib.mkOption {
    type = lib.types.str;
    description = "Username of the primary fleet admin for this machine.";
  };

  config = {
    environment.variables = {
      FLEET_ADMIN = config.fleet.admin;
      FLEET_ROOT = fleetRoot;
    };

    home-manager.extraSpecialArgs = {
      username = config.fleet.admin;
    };
  };
}
