{ pkgs, pkgs-unstable, config, ... }:

{
  imports = [ ../profiles/agents.nix ../profiles/nvim.nix ../profiles/lsp.nix ../profiles/copilot.nix ../profiles/jujutsu.nix ../profiles/fleet-sync.nix ];

  home.packages = (with pkgs; [
    pkg-config
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
    azure-cli
		devenv
  ]);

  home.sessionVariables = {
    GOPRIVATE = "github.com/Azure/azure-cosmos-client-engine";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.sessionPath = [ "$HOME/.npm-global/bin" "$HOME/.config/agency/CurrentVersion" ];
}
