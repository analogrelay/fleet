{ lib, tags, pkgs, pkgs-unstable, pkgs-analogrelay, ... }:

{
  imports = [
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

  # A test secret that allows for checking that the secret management is working.
  fleet.secrets."test" = {
    source = "op://Fleet/TestSecret/credential";
    required = false;
    mode = "0444";
  };

  environment.systemPackages = with pkgs; [
    zsh
    nix
    pkg-config
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      icu
      openssl
    ];
  };
}
