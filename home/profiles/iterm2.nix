{ pkgs, lib, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in

{
  home.packages = with pkgs; [
    iterm2
  ];

  home.file.".config/iterm2/com.googlecode.iterm2.plist".source =
    fleetLink "home/profiles/com.googlecode.iterm2.plist";

  home.activation.iterm2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$(echo ~/.config/iterm2)"
    /usr/bin/defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
  '';
}