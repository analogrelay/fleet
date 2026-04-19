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

  services.caddy.virtualHosts."jellyfin.analogrelay.net" = {
    extraConfig = ''
      tls { 
        dns azure {
          subscription_id {$AZURE_SUBSCRIPTION_ID}
          resource_group_name {$AZURE_RESOURCE_GROUP_NAME}
          tenant_id {$AZURE_TENANT_ID}
          client_id {$AZURE_CLIENT_ID}
          client_secret {$AZURE_CLIENT_SECRET}
        }
      }
      reverse_proxy 127.0.0.1:8096
    '';
  };
}
