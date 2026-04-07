{ pkgs, config, ... }:

{
  services.nzbget = {
    enable = true;
    settings = {
      MainDir = "/var/lib/nzbget/config";
      DestDir = "/mnt/tank/downloads/nzbget";
    };
  };
  networking.firewall.allowedTCPPorts = [ 6789 ];

  users.users.radarr.extraGroups = [ "share" ];

  services.jackett = {
    enable = true;
    openFirewall = true;
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = 7880;
    torrentingPort = 7881;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    settings = {
      auth.method = "external";
      server = {
        urlbase = "localhost";
        port = 7878;
        bindaddress = "*";
      };
    };
  };
}
