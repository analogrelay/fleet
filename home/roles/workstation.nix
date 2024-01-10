{ pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    kubectl
    k9s
    azure-cli
  ];
}
