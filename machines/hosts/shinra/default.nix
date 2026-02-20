{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../platform.nix

    ../../users

    ../../profiles/syncthing.nix
    ../../profiles/k3s/agent.nix
    ../../profiles/tailnet.nix
  ];

  networking.hostName = "shinra";

  system.stateVersion = "24.05";

  fleet.admin = "ashley";
  fleet.platform = "nixos";
  fleet.role = "workstation";
  fleet.realm = "analoghome";

  # Create volumes for Kubernetes
  systemd.tmpfiles.rules = [
    "d /var/volumes/postgres 2775 k8s share - -"
  ];

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "ashley";
  services.desktopManager.plasma6.enable = true;

  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.openFirewall = true;
}
