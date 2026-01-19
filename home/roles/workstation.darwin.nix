{ pkgs, lib, ... }:

let
  rust-rover =
    pkgs.jetbrains.rust-rover.overrideAttrs { buildNumber = "233.13135.116"; };
in {
  imports = [ ../profiles/iterm2.nix ];

  # 1Password SSH agent
  programs.ssh.matchBlocks."*".extraOptions = {
    "IdentityAgent" =
      ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
  };

  programs.git.settings.gpg.ssh.program =
    "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
}
