{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  pkgs-analogrelay,
  ...
}:

let
  cfg = config.fleet;
in
{
  imports = [
    ./fleet.nix
    ./${cfg.platform}.nix
  ]
  ++ (lib.optional (builtins.pathExists ./roles/${cfg.role}.nix)
    ./roles/${cfg.role}.nix)
  ++ (lib.optional (builtins.pathExists ./roles/${cfg.role}.${cfg.platform}.nix)
    ./roles/${cfg.role}.${cfg.platform}.nix)
  ++ (lib.optional (cfg.realm != null && builtins.pathExists ./realms/${cfg.realm}.nix)
    ./realms/${cfg.realm}.nix)
  ++ (lib.optional (cfg.realm != null && builtins.pathExists ./realms/${cfg.realm}.${cfg.platform}.nix)
    ./realms/${cfg.realm}.${cfg.platform}.nix);

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit pkgs-unstable pkgs-analogrelay;
    };
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    zsh
    nix
  ];
}
