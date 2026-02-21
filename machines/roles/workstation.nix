{ config, lib, pkgs, ... }:

let
  cfg = config.fleet;
in
{
  config = lib.mkIf (cfg.role == "workstation") {
    fonts.packages = with pkgs; [
      monaspace
      nerd-fonts.monaspace
      nerd-fonts.zed-mono
    ];
  };
}
