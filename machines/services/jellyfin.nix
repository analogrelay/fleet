{ ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.fail2ban.serviceConfig.SupplementaryGroups = [ "jellyfin" ];

  # ── fail2ban: ban IPs after repeated Jellyfin login failures ──────────
  services.fail2ban.jails.jellyfin.settings = {
    enabled      = true;
    maxretry     = 5;
    filter       = "jellyfin";
    action       = "remote-ban";
    backend      = "systemd";
    journalmatch = "_SYSTEMD_UNIT=jellyfin.service";
  };

  environment.etc."fail2ban/filter.d/jellyfin.local".text =
    ''
    [Definition]
    failregex = ^.*Authentication request for .* has been denied \(IP: <HOST>\)\.
    ignoreregex =
    '';
}
