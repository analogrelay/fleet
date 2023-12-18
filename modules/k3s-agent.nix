{ config, lib, pkgs, inputs, ... }:

{
  sops.secrets.k3s_token.sopsFile = ../secrets/secrets.yaml;

  environment.systemPackages = [ pkgs.k3s ];

  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.sops.secrets.k3s_token.path;
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s API
  ];
  networking.firewall.allowedUDPPorts = [
  ];
}