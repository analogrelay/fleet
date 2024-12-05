{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix
      ../../realms/analoghome.nix

      ../../users

      ../../roles/server.nix

      ../../profiles/syncthing.nix
      ../../profiles/k3s/agent.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "shinra";

  system.stateVersion = "24.05";

  # Create volumes for Kubernetes
  systemd.tmpfiles.rules = [
      "d /var/volumes/postgres 2775 k8s share - -"
  ];

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.openFirewall = true;
}

