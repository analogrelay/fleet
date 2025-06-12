{ config, lib, pkgs, ... }:

{
  security.pam.services.sudo_local.touchIdAuth = true;

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  home-manager.extraSpecialArgs = {
    os = "darwin";
    wsl = false;
  };

  environment.systemPackages = with pkgs; [ ];
}
