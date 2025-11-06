# cSpell:ignore usbip

{ ... }:

{
  imports = [ ./nixos.nix ];

  home-manager.extraSpecialArgs = { wsl = true; };

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
