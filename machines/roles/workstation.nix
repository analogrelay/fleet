{ pkgs, platform, wsl, ... }:

{
  imports = [
    ./workstation.${platform}.nix
  ];

  home-manager.extraSpecialArgs = {
    role = "workstation";
  };
}