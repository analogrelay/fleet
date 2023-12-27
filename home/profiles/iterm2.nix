{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    iterm2
  ];

  home.file.".config/iterm2/com.googlecode.iterm2.plist".source = ./com.googlecode.iterm2.plist;

  home.activation.iterm2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$(echo ~/.config/iterm2)"
    /usr/bin/defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
  '';
}