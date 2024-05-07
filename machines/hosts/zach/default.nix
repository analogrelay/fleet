{ config, lib, pkgs, ... }:

{
  imports = [
    ../../platform.nix
    ../../roles/workstation.nix

    ../../profiles/k3s/agent.nix

    ../../users/ashley.nix
  ];

  networking.hostName = "zach";

  wsl.defaultUser = "ashley";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  services.k3s = {
    # Mark this node so that it isn't scheduled on by default.
    extraArgs = "--node-label transient=true:NoSchedule";
  };

  home-manager.extraSpecialArgs = {
    username = "ashley";
  };
}