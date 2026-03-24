# Fleet + home-manager integration module.
# Import this alongside home-manager.nixosModules.home-manager to wire fleet
# options through to home-manager as specialArgs.
{ config, lib, secrets ? { }, ... }:

let
  cfg = config.fleet;
  os = if cfg.platform == "darwin" then "darwin" else "linux";
  wsl = cfg.platform == "wsl";
in
{
  home-manager.extraSpecialArgs = {
    inherit secrets;
    tags = {
      inherit os wsl;
      role = cfg.role;
      runtime = cfg.runtime;
      realm = cfg.realm;
      platform = cfg.platform;
      identity = cfg.identity;
    };
  };
}
