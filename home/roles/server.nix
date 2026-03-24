{ pkgs, ... }:

{
  imports = [ ../profiles/fleet-sync.nix ];

  home.packages = with pkgs; [
  ];
}
