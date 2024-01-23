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

  home.packages = with pkgs; [
    defaultbrowser
    microsoft-edge-stable
    spotify
    zoom-us
  ];

  home.activation.defaultBrowser = lib.hm.dag.entryAfter ["installPackages"] ''
    $DRY_RUN_CMD ${lib.getExe pkgs.defaultbrowser} edgemac
  '';

  # 1Password SSH agent
  programs.ssh.matchBlocks."*".extraOptions = {
    "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  ];
}
