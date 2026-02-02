{
  pkgs,
  pkgs-unstable,
  config,
  ...
}:

{
  imports = [ ];

  home.packages =
    (with pkgs; [
      kubectl
      k9s
      powershell
      (azure-cli.withExtensions [
        azure-cli.extensions.azure-devops
      ])
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
      cmake
      gnumake
    ])
    ++ (with pkgs-unstable; [
      claude-code
      opencode
      github-copilot-cli
    ]);

  home.sessionVariables = {
    GOPRIVATE = "github.com/Azure/azure-cosmos-client-engine";
  };
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.sessionPath = [ "$HOME/.npm-global/bin" ];
}
