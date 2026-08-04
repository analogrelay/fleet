{ pkgs, pkgs-unstable, config, ... }:

{
  imports = [ ../profiles/nvim.nix ../profiles/lsp.nix ];

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
    nodejs_24
    cmake
    gnumake
    uv
    bun
    ripgrep
  ]) ++ (with pkgs-unstable;
    [ (azure-cli.withExtensions [ azure-cli.extensions.azure-devops ]) ]);

  home.sessionVariables = {
    GOPRIVATE = "github.com/Azure/azure-cosmos-client-engine";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.out}/include";
  };
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.sessionPath =
    [ "$HOME/.npm-global/bin" "$HOME/.config/agency/CurrentVersion" ];
}
