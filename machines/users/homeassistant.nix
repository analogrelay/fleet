{ lib, pkgs, ... }:

{
  users.users.homeassistant = {
    uid = 2000;
    description = "Home Assistant";
    shell = pkgs.zsh;
    home = "/home/homeassistant";
    isNormalUser = true;
    extraGroups = [ "share" ];
  };
}
