{ lib, ... }:

{
  boot.isContainer = true;

  # Disable hardware/network services that don't apply in containers
  networking.networkmanager.enable = lib.mkForce false;
  virtualisation.containers.enable = lib.mkForce false;
  virtualisation.podman.enable = lib.mkForce false;

  # No hardware packages needed
  environment.systemPackages = lib.mkForce [ ];
}
