{ lib, tags, pkgs, pkgs-unstable, pkgs-analogrelay, ... }:

{
  imports = [
    ./fleet.nix
    ./${tags.platform}.nix
  ]
  ++ lib.optional (builtins.pathExists ./roles/${tags.role}.nix)
    ./roles/${tags.role}.nix
  ++ lib.optional (builtins.pathExists ./roles/${tags.role}.${tags.platform}.nix)
    ./roles/${tags.role}.${tags.platform}.nix
  ++ lib.optional (tags ? runtime && builtins.pathExists ./runtimes/${tags.runtime}.nix)
    ./runtimes/${tags.runtime}.nix
  ++ lib.optional (tags.realm != null && builtins.pathExists ./realms/${tags.realm}.nix)
    ./realms/${tags.realm}.nix
  ++ lib.optional (tags.realm != null && builtins.pathExists ./realms/${tags.realm}.${tags.platform}.nix)
    ./realms/${tags.realm}.${tags.platform}.nix;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
		backupFileExtension = "hm-bak";
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
