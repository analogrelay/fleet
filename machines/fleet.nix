{ config, lib, pkgs, secrets ? {}, ... }:

let
  cfg = config.fleet;
  adminHome = config.users.users.${cfg.admin}.home;
  os = if cfg.platform == "darwin" then "darwin" else "linux";
  wsl = cfg.platform == "wsl";
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

    platform = lib.mkOption {
      type = lib.types.enum [ "nixos" "wsl" "darwin" ];
      description = "The platform type for this machine.";
    };

    role = lib.mkOption {
      type = lib.types.enum [ "server" "workstation" ];
      description = "The role of this machine.";
    };

    realm = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The network realm this machine belongs to.";
    };

    identity = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "The fleet identity of this machine. Used for secret loading and fleet management.";
    };
  };

  config = {
    environment.variables = {
      FLEET_ADMIN = cfg.admin;
      FLEET_ROOT = cfg.root;
      FLEET_IDENTITY = cfg.identity;
    };

    home-manager.extraSpecialArgs = {
      username = cfg.admin;
      inherit secrets;
      tags = {
        inherit os wsl;
        role = cfg.role;
        realm = cfg.realm;
        platform = cfg.platform;
        identity = cfg.identity;
      };
    };
  };
}
