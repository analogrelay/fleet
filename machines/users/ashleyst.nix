{ lib, pkgs, config, ... }:

let
  defaultConfig = {
    uid = 1000;
    description = "Ashley Stanton-Nurse";
    shell = pkgs.zsh;
  };
  linuxUser = defaultConfig // {
    home = "/home/ashleyst";
    isNormalUser = true;
    initialHashedPassword = "$y$j9T$q0Sl6jJo8lxrJkXt3p2yq0$c0rXC6qssKoj2GSPtmrgOnbwXOEcUe8qLxChOJrP0s.";
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "docker"
    ];
  };
  darwinUser = defaultConfig // {
    home = "/Users/ashleyst";
  };
in
{
  users.users.ashleyst = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isLinux linuxUser)
    (lib.mkIf pkgs.stdenv.isDarwin darwinUser)
  ];

  home-manager.users.ashleyst = {
    imports = [
      ../../home
    ] ++ lib.optional (builtins.pathExists ../../home/hosts/${config.networking.hostName}.nix) ../../home/hosts/${config.networking.hostName}.nix;
  };
  nix.settings.trusted-users = [ "ashleyst" ];
}