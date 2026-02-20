{ config, lib, pkgs, ... }:

let
  adminHome = config.users.users.${config.fleet.admin}.home;
in
{
  options.fleet = {
    admin = lib.mkOption {
      type = lib.types.str;
      description = "Username of the primary fleet admin for this machine.";
    };

    root = lib.mkOption {
      type = lib.types.str;
      default = "${adminHome}/.config/fleet";
      description = "Absolute path to the fleet repository checkout.";
    };
  };

  config = {
    environment.variables = {
      FLEET_ADMIN = config.fleet.admin;
      FLEET_ROOT = config.fleet.root;
    };

    home-manager.extraSpecialArgs = {
      username = config.fleet.admin;
    };
  };
}
