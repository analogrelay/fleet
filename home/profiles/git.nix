{ pkgs, lib, wsl, ... }:

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
      init.defaultBranch = "main";
      color.ui = true;
      pull.rebase = true;
      gpg.format = "ssh";
    } // (if pkgs.stdenv.isDarwin then {
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    } else {}) // (if wsl then {
      # Use the Windows SSH executable.
      core.sshCommand = "ssh.exe";
      "gpg \"ssh\"".program = "/mnt/c/Users/ashley/AppData/Local/1Password/app/8/op-ssh-sign.exe";
    } else {});
  };
}