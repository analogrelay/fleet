{ pkgs, pkgs-unstable, config, ... }:

{
  imports = [ ../profiles/nvim.nix ../profiles/lsp.nix ../profiles/fleet-sync.nix ];

  home.packages = (with pkgs; [
    openssl
    powershell
    rustup
    git-credential-manager
    gh
    lazygit
    jq
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
  ]) ++ (with pkgs-unstable; [
    (azure-cli.withExtensions [azure-cli.extensions.azure-devops])
    devenv
  ]);

  home.sessionVariables = {
    GOPRIVATE = "github.com/Azure/azure-cosmos-client-engine";
  };
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.sessionPath = [ "$HOME/.npm-global/bin" "$HOME/.config/agency/CurrentVersion" ];
}
