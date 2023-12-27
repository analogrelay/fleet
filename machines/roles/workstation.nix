{ pkgs, platform, ... }:

{
  imports = [
    ./workstation.${platform}.nix
  ];

  environment.systemPackages = with pkgs; [
    _1password-gui
  ];

  home-manager.extraSpecialArgs = {
    role = "workstation";
  };
}