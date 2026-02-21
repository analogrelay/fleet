# cSpell:ignore usbip

{ config, lib, ... }:

let
  cfg = config.fleet;
in
{
  config = lib.mkIf (cfg.platform == "wsl") {
    programs.nix-ld.enable = true;

    wsl = {
      enable = true;
      usbip.enable = true;
    };

    services.openssh = {
      enable = true;
      ports = [ 2222 ];
    };
  };
}
