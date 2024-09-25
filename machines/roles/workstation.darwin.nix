{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      monaspace
      monaspice
    ];
  };

  environment.systemPackages = [
  ];
}