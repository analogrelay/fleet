{ modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Includes support for r8125 network driver
  boot.kernelPackages = pkgs.linuxPackages_6_13;

  networking.wireless.enable = false;
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  networking.hostName = "live";

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    zsh
    nix-index
    tmux
    nix
    nixpkgs-fmt
  ];
}

