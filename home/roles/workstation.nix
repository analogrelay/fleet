{ pkgs, config, ... }:

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
    python3
    pipx
    nodejs_24
  ];

  home.sessionVariables = {
    GOPRIVATE = "github.com/Azure/azure-cosmos-client-engine";
  };
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.sessionPath = [ "$HOME/.npm-global/bin" ];
}
