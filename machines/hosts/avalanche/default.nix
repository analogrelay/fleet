{ pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix
      ../../realms/analoghome.nix
      ../../roles/server.nix

      ../../users

      ../../profiles/syncthing.nix
      ../../profiles/nas.nix
      ../../profiles/k3s/server.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "avalanche";

  system.stateVersion = "24.11";

  # We want to do ARM things sometimes
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };

  services.beesd.filesystems.data = {
    spec = "LABEL=DATA";
    hashTableSizeMB = 128;
  };

  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_1.gasket
  ];
}

