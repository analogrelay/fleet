{ pkgs, lib, ... }:

let
  rust-rover = pkgs.jetbrains.rust-rover.overrideAttrs {
    buildNumber = "233.13135.116";
  };
in
{
  imports = [
    ../profiles/iterm2.nix
  ];

  # 1Password SSH agent
  programs.ssh.matchBlocks."*".extraOptions = {
    "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  ];
}
