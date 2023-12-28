{ pkgs, ... }:

{
  networking.domain = "node.analogrelay.net";
  networking.networkmanager.enable = true;

  # This can be overridden on a per-host basis
  time.timeZone = "America/Vancouver";

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  home-manager.extraSpecialArgs = {
    os = "linux";
    distro = "nixos";
  };
}
