{ config, lib, pkgs, inputs, ... }:

{
  security.pam.services.sudo_local.touchIdAuth = true;

  nix = {
    linux-builder = {
      enable = true;
      config = { virtualisation.darwin-builder.memorySize = 8192; };
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };

  home-manager.extraSpecialArgs = {
    os = "darwin";
    wsl = false;
  };

  environment.systemPackages = with pkgs; [ ];
}
