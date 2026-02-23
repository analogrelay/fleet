{ pkgs, config, ... }:

{
  imports = [
    ../../platform.nix
    ../../users/ashley.nix
  ];

  networking.hostName = "devenv";

  system.stateVersion = "24.11";

  system.build.dockerImage = pkgs.dockerTools.buildLayeredImage {
    name = "fleet-devenv";
    tag = "latest";
    contents = with pkgs; [
      bashInteractive
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      nix
      git
      curl
      wget
      zsh
      config.system.path
    ];
    config = {
      Cmd = [ "${pkgs.bashInteractive}/bin/bash" ];
      Env = [
        "NIX_CONF_DIR=/etc/nix"
        "PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      ];
    };
  };
}
