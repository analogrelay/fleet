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
}
