{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")

    ../../platform.nix
    ../../users/ashley.nix
  ];
  networking.wireless.enable = false; # We use networkmanager in platform.nix
  networking.hostName = "live";
  home-manager.extraSpecialArgs = {
    role = "image";
    username = "ashley";
  };
}

