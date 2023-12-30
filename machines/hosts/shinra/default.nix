{ ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ../../platform.nix

      ../../users

      ../../roles/server.nix

      ../../profiles/k3s/agent.nix
      ../../profiles/tailnet.nix
    ];

  networking.hostName = "shinra";

  system.stateVersion = "23.11";

  # Create volumes for Kubernetes
  systemd.tmpfiles.rules = [
      "d /var/volumes/postgres 2775 k8s share - -"
  ];
}

