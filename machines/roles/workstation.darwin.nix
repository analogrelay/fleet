{ pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      monaspace
      monaspice
    ];
  };

  environment.systemPackages = [
    pkgs._1password-gui
  ];
}