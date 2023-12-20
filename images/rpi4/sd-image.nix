# Enough to build an image that can be SSHed to

{ ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
    ../../modules/users.nix
  ];

  system.stateVersion = "23.11";
}