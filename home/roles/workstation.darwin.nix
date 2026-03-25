{ pkgs, lib, ... }:

let
  rust-rover =
    pkgs.jetbrains.rust-rover.overrideAttrs { buildNumber = "233.13135.116"; };
in {
  imports = [ ../profiles/iterm2.nix ];

  programs.git.settings.gpg.ssh.program =
    "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
}
