{ pkgs, ... }:

{
  networking.domain = "node.analogrelay.net";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  # This can be overridden on a per-host basis
  time.timeZone = "America/Vancouver";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  virtualisation.docker.enable = true;

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    cifs-utils
    nfs-utils
    usbutils
    pciutils
    hw-probe
  ];

  home-manager.extraSpecialArgs = {
    os = "linux";
    distro = "nixos";
    wsl = false;
  };

  users = { groups = { unattend = { gid = 6000; }; }; };
}
