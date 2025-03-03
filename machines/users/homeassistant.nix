{ lib, pkgs, ... }:

{
  users.users.homeassistant = {
    uid = 2000;
    description = "Home Assistant";
    shell = pkgs.zsh;
    home = "/home/homeassistant";
    isNormalUser = true;
    initialHashedPassword = "$y$j9T$q0Sl6jJo8lxrJkXt3p2yq0$c0rXC6qssKoj2GSPtmrgOnbwXOEcUe8qLxChOJrP0s.";
    extraGroups = [ "share" ];
  };
}
