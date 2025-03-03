{ config, lib, pkgs, ... }:

{
  services.nix-daemon.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

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
