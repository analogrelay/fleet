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
    gh
    lazygit
    jq
    devenv
    _1password-gui
  ];

  programs.ssh.matchBlocks."*".extraOptions = {
    "IdentityAgent" = "~/.1password/agent.sock";
  };
}
