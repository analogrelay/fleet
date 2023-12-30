{ pkgs, lib, ... }:

{
  imports = [
    ../profiles/iterm2.nix
  ];

  home.packages = with pkgs; [
    defaultbrowser
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
  ];
}
