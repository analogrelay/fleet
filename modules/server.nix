{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.cifs-utils ];
}