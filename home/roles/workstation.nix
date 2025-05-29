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
    dotnet-sdk_9
    _1password-gui
    go
  ];
}
