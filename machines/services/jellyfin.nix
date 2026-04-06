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
    action       = "cloudflare-list";
    backend      = "systemd";
    journalmatch = "_SYSTEMD_UNIT=jellyfin.service";
  };

  environment.etc."fail2ban/filter.d/jellyfin.local".text =
    ''
    [Definition]
    failregex = ^.*Authentication request for .* has been denied \(IP: <HOST>\)\.
    ignoreregex =
    '';

  services.cloudflared.tunnels."a0306444-7c05-4c03-9152-d6c09e116854".ingress = {
    "jellyfin.analogrelay.net" = "http://localhost:8096";
  };
}
