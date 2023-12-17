{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.k3s ];

  networking.firewall.allowedTCPPorts = [
    6443 # k3s API
  ];
  networking.firewall.allowedUDPPorts = [
  ];
}