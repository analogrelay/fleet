{ pkgs, username, lib, ... }:

{
  imports = [ ];
  home.homeDirectory = "/Users/${username}";
}
