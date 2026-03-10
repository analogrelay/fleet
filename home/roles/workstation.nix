{ pkgs, pkgs-unstable, config, ... }:

{
  imports = [ ../profiles/nvim.nix ../profiles/lsp.nix ../profiles/copilot.nix ../profiles/jujutsu.nix ];

  home.packages = (with pkgs; [
    kubectl
    k9s
    powershell
    rustup
    git-credential-manager
    gh
    lazygit
    jq
    devenv
    # werx # temporarily disabled — package is broken
    go
    python3
    pipx
    nodejs_24
    cmake
    gnumake
    uv
    bun
    ripgrep
  ]);

  home.sessionVariables = {
    GOPRIVATE = "github.com/Azure/azure-cosmos-client-engine";
  };
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.sessionPath = [ "$HOME/.npm-global/bin" ];
}
