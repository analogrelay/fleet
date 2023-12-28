{ config, lib, ... }:

{
  services.nix-daemon.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  home-manager.extraSpecialArgs = {
    os = "darwin";
  };

  # macOS apps expect to be in /Applications
  # Nix tries to symlink them, but it doesn't really work out well.
  # So instead we'll delete that symlink and copy the apps.
  # We track the original paths in a `.copies` file so we only have to update them when a new derivation is built for the app.
  system.activationScripts.applications.text = lib.mkForce ''
    ${../script/_utils/copy-apps.sh} "$(echo /Applications)" "${config.system.build.applications}/Applications"
  '';
}