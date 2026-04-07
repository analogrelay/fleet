{ pkgs, config, ... }:

{
  services.sillytavern = {
    enable = true;
    whitelist = false;
  };
  
  # The sillytavern `listen` arg is broken
  systemd.services.sillytavern.serviceConfig.ExecStart = pkgs.lib.mkForce
    "${pkgs.lib.getExe pkgs.sillytavern} --port 50505 --listen";
  systemd.tmpfiles.settings.sillytavern."/var/lib/SillyTavern/config.yaml" = pkgs.lib.mkForce {};
  networking.firewall.allowedTCPPorts = [ 50505 ];

  services.cloudflared.tunnels."a0306444-7c05-4c03-9152-d6c09e116854".ingress = {
    "tavern.analogrelay.net" = "http://localhost";
  };
}
