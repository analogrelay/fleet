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
      gpg.format = "ssh";
      "gpg \"ssh\"".program = if pkgs.stdenv.isDarwin 
        then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else throw "Not supported on non-Darwin platforms yet!";
    };
  };
}