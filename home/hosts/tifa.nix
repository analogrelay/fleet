{ pkgs, ... }:

{
  imports = [ ../profiles/local-ai.nix ];
  home.packages = [
    pkgs.display-switch
  ];
  home.file."Library/Preferences/display-switch.ini" = {
    enable = true;
    onChange = "";
    text = ''
      usb_device = "3434:01a1"
      on_usb_connect = "DisplayPort1"
    '';
  };
  launchd.agents."display-switch" = {
    enable = true;
    config = {
      Label = "dev.haim.display-switch.daemon";
      Program = pkgs.lib.getExe pkgs.display-switch;
      RunAtLoad = true;
    };
  };
}
