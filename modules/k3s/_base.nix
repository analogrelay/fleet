{ config, lib, pkgs, inputs, ... }:

{
  sops.secrets.k3s_token.sopsFile = ../../secrets/secrets.yaml;

  environment.systemPackages = [ pkgs.k3s ];

  services.k3s = {
    enable = true;
    tokenFile = config.sops.secrets.k3s_token.path;
  };

  networking.firewall.allowedTCPPorts = [
    6443 # kubernetes
    2379 # etcd
    2380 # etcd
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # flannel
  ];

  # Create groups and users for k8s services
  users = {
    groups = {
      k8s = {
        gid = 1000;
      };
    };
    users = {
      k8s = {
        uid = 1003;
        description = "Kubernetes User";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ 
            "k8s"
            "share"
        ];
      };
    };
  };
}
