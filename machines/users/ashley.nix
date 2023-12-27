{ lib, pkgs, ... }:

let 
  defaultConfig = {
    description = "Ashley Stanton-Nurse";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
        ../../keys/1password.pub
        ../../keys/jenova.pub
    ];
  };
  linuxUser = defaultConfig // {
    home = "/home/ashley";
    isNormalUser = true;
    extraGroups = [
      "wheel" 
      "networkmanager" 
      "libvirtd"
      "docker"
      "share"
      "family"
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
}