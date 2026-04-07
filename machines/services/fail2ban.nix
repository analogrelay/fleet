{ pkgs, config, ... }:

let
  curl = "${pkgs.curl}/bin/curl";
  jq = "${pkgs.jq}/bin/jq";
in
{
  services.fail2ban = {
    enable = true;
  };

  environment.systemPackages = [
    pkgs.fail2ban
    pkgs.jq
  ];

  users.groups.fail2ban = { };
  environment.etc."fail2ban/action.d/remote-ban.conf".text = ''
    [Definition]

    actionban   = ${pkgs.openssh}/bin/ssh -i <ssh_key> -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 <ssh_user>@<vps_host> "ban-ip <ip> <ban_timeout> <n>"
    actionunban = ${pkgs.openssh}/bin/ssh -i <ssh_key> -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 <ssh_user>@<vps_host> "unban-ip <ip>"
    actionstart = ${pkgs.openssh}/bin/ssh -i <ssh_key> -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 <ssh_user>@<vps_host> "list-bans" > /dev/null
    actionstop  =

    [Init]
    vps_host = 
    ssh_key = 
    ssh_user = root
    ban_timeout = 86400
  '';

  environment.etc."fail2ban/action.d/remote-ban.local".text = ''
    [Init]
    vps_host = aerith.bicorn-bebop.ts.net
    ssh_key = /run/secrets/aerith-ban
  '';

  # Ensure fail2ban starts after secrets have been provisioned.
  systemd.services.fail2ban = {
    after = [ "provision-fleet-secrets.service" ];
    wants = [ "provision-fleet-secrets.service" ];
    serviceConfig.SupplementaryGroups = [ "fail2ban" ];
  };
}
