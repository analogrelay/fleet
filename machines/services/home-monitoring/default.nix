{ pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (p: [
    p.prometheus-client
  ]);
  script = pkgs.writeScript "tou-rate-exporter.py" (builtins.readFile ./tou-rate-exporter.py);
in {
  systemd.services.tou-rate-exporter = {
    description = "Time-of-use energy rate Prometheus exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pythonEnv}/bin/python3 ${script}";
      Restart = "on-failure";
      DynamicUser = true;
      RuntimeDirectory = "tou-rate-exporter";
      RuntimeDirectoryMode = "0755";
    };
  };

  systemd.services.shelly-exporter = {
    description = "Shelly power monitor exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.lib.getExe pkgs.shelly-exporter} -config /etc/shelly-exporter.yaml";
      Restart = "on-failure";
      DynamicUser = true;
    };
  };

  environment.etc."shelly-exporter.yaml".text = ''
    listenAddress: :10101
    debug: false
    deviceUpdateInterval: 30
    devices:
    - host: 192.168.4.1
    - host: 192.168.4.2
    - host: 192.168.4.3
  '';
  networking.firewall.allowedTCPPorts = [ 10101 ];
}
