{ pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "Ashley Stanton-Nurse";
    userEmail = "git@analogrelay.net";
    signing = {
      key = builtins.readFile ../../keys/gitSigning.pub;
      signByDefault = true;
    };
    extraConfig = {
      pull.rebase = true;
      gpg.format = "ssh";
    } // (if pkgs.stdenv.isDarwin then {
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    } else {});
  };
}