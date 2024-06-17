{ pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    kubectl
    k9s
    azure-cli
    rustup
    git-credential-manager
    pulumi
    gh
    lazygit
    jq
  ];
}
