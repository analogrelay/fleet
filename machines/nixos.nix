{ pkgs, ... }:

{
  networking.domain = "node.analogrelay.net";
  networking.networkmanager.enable = true;

  # This can be overridden on a per-host basis
  time.timeZone = "America/Vancouver";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  virtualization.docker.enable = true;

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    cifs-utils
    nfs-utils
  ];

  home-manager.extraSpecialArgs = {
    os = "linux";
    distro = "nixos";
  };

  # Create fleet-wide groups and users, which all have consistent GIDs/UIDs which start with 5000
  users = {
    groups = {
      family = {
        gid = 5000;
      };
      parents = {
        gid = 5001;
      };
      kids = {
        gid = 5002;
      };
      share = {
        gid = 5003;
      };
    };

    users = {
      share = {
        uid = 5000;
        description = "Share User";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ 
            "share"
        ];
      };
    };
  };
}
