{ config, lib, pkgs, ... }:

{
  programs.zsh.enable = true;

  networking.domain = "home.analogrelay.net";
  networking.networkmanager.enable = true;

  # This can be overridden on a per-host basis
  time.timeZone = "America/Vancouver";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    zsh
    nix-index
    cifs-utils
    tmux
  ];

  users.groups = {
    share = {
      gid: 992;
    };
    family = {
      gid: 993; 
    };
  };

  services.openssh.enable = true;
}