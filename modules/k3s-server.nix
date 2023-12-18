{ config, lib, pkgs, inputs, ... }:

{
  age.secrets.k3s-secrets.file = "${inputs.secrets}/secrets/k3s-token.age";

  environment.systemPackages = [ pkgs.k3s ];

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s-token.path;
  };

  networking.firewall.allowedTCPPorts = [
    6443 # k3s API
  ];
  networking.firewall.allowedUDPPorts = [
  ];
}