{ lib, pkgs, ... }:

let
  defaultConfig = {
    uid = 1000;
    description = "Ashley Stanton-Nurse";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../keys/local-server-admin.pub)
    ];
  };
  linuxUser = defaultConfig // {
    home = "/home/ashley";
    isNormalUser = true;
    initialHashedPassword = "$y$j9T$q0Sl6jJo8lxrJkXt3p2yq0$c0rXC6qssKoj2GSPtmrgOnbwXOEcUe8qLxChOJrP0s.";
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "docker"
      "share"
      "family"
      "parents"
      "aria2"
    ];
  };
  darwinUser = defaultConfig // {
    home = "/Users/ashley";
  };
in
{
  users.users.ashley = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.isLinux linuxUser)
    (lib.mkIf pkgs.stdenv.isDarwin darwinUser)
  ];

  home-manager.users.ashley = {
    imports = [
      ../../home
    ];
  };
  nix.settings.trusted-users = [ "ashley" ];
}
