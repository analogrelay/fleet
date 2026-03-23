{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../platform.nix
    ../../users
    ../../services/traefik.nix
    ../../services/homedb.nix
    ../../services/paperless.nix
  ];

  networking.hostName = "shinra";

  system.stateVersion = "25.11";

  # shinra is a laptop running with lid closed
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  fileSystems."/mnt/avalanche/shares/public" = {
    device = "avalanche.analogno.de:/mnt/data/shares/public";
    fsType = "nfs";
    options = [ "_netdev" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=30s" ];
  };

  fileSystems."/mnt/avalanche/k3s/shares" = {
    device = "avalanche.analogno.de:/mnt/data/k3s/shares";
    fsType = "nfs";
    options = [ "_netdev" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=600" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=30s" ];
  };
}
