{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../platform.nix
    ../../users
    ../../services/traefik.nix
  ];

  networking.hostName = "shinra";

  system.stateVersion = "24.05";

  # shinra is a laptop running with lid closed
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # NFS mounts from avalanche — lazy automount, won't block boot if unreachable
  fileSystems."/mnt/avalanche/shares/public" = {
    device = "avalanche.node.analogrelay.net:/mnt/data/shares/public";
    fsType = "nfs";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };

  fileSystems."/mnt/avalanche/k3s/shares" = {
    device = "avalanche.node.analogrelay.net:/mnt/data/k3s/shares";
    fsType = "nfs";
    options = [
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };
}
