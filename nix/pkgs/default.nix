# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{ pkgs }: {
  shelly-exporter = pkgs.callPackage ./shelly-exporter {};
  display-switch = pkgs.callPackage ./display-switch {};
  es-de = pkgs.callPackage ./es-de {};
  plannotator = pkgs.callPackage ./plannotator {};
  remote-ban = pkgs.callPackage ./remote-ban {};
}
