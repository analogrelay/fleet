{ pkgs, ... }:

{
  imports = [ ];

  home.packages = with pkgs; [
    kubectl
    k9s
    azure-cli
    rustup
    git-credential-manager
    gh
    lazygit
    jq
    devenv
    go
  ];
}
