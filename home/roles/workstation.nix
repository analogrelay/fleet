{ pkgs, ... }:

{
  imports = [
    ../profiles/shell.nix
    ../profiles/vscode.nix
  ];

  programs.fzf.enable = true;

  home.packages = with pkgs; [
    microsoft-edge-stable
  ];

  # 1Password SSH agent
  programs.ssh.matchBlocks."*".extraOptions = {
    "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
  };
}
