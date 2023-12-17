{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    zsh
  ];

  services.openssh.enable = true;
}