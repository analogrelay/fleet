# cSpell:ignore usbip

{ ... }:

{
  programs.nix-ld.enable = true;

  wsl = {
    enable = true;
    usbip.enable = true;
  };

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
  };
}
