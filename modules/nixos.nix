{ config, lib, pkgs, ... }:

{
  imports = [
    ./_base.nix
  ];

  networking.domain = "home.analogrelay.net";
  networking.networkmanager.enable = true;

  # This can be overridden on a per-host basis
  time.timeZone = "America/Vancouver";

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
}