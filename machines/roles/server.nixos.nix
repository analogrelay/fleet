{ config, lib, ... }:

let
  cfg = config.fleet;
in
{
  config = lib.mkIf (cfg.role == "server") {
    services.iperf3 = {
      enable = true;
      openFirewall = true;
      port = 7575;
    };
  };
}
