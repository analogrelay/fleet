{ pkgs, ... }:

{
  users.users.rclone = {
    isSystemUser = true;
    group = "rclone";
    home = "/var/lib/rclone/";
  };
  users.groups.rclone = {};

  systemd.services.rclone = {
    description = "rclone Remote Control";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      User = "rclone";
      ExecStart = "${pkgs.rclone}/bin/rclone rcd --rc-addr 0.0.0.0:5572 --rc-web-gui --rc-web-gui-no-open-browser --rc-no-auth --rc-enable-metrics";
    };
  };
  networking.firewall.allowedTCPPorts = [ 5572 ];
}
