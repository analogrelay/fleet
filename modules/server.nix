{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cifs-utils ];

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=local-storage"
    ];
  };
}