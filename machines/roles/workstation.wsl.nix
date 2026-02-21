{ config, lib, ... }:

let
  cfg = config.fleet;
in
{
  config = lib.mkIf (cfg.role == "workstation" && cfg.platform == "wsl") {
    services.openssh = {
      enable = true;
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 2222;
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 2222 ];
  };
}
