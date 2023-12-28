{ pkgs, ... }:

{
  imports = [
    ../profiles/shell.nix
    ../profiles/vscode.nix
  ];

  home.packages = with pkgs; [
    microsoft-edge-stable
    kubectl
    k9s
    azure-cli
  ];
}
