{ lib, ... }:

{
  imports = [
  ];

  # User-installed macOS apps expect to be in ~/Applications
  # Home Manager tries to symlink them, but it doesn't really work out well.
  # So instead we'll delete that symlink and copy the apps.
  # We track the original paths in a `.copies` file so we only have to update them when a new derivation is built for the app.
  home.activation.copyApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${../script/_utils/copy-apps.sh} "$(echo ~/Applications)" "$genProfilePath/home-path/Applications"
  '';
}