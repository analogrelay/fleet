{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = pkgs.lib.mkDefault "Ashley Stanton-Nurse";
    userEmail = pkgs.lib.mkDefault "git@analogrelay.net";
    signing = {
      key = builtins.readFile ../../keys/gitSigning.pub;
      signByDefault = true;
    };
    includes = [
      { path = "~/.config/git/config.d/base.gitconfig"; }
      { path = "~/.config/git/config.d/local.gitconfig"; }
    ];
    extraConfig = {
      init.defaultBranch = "main";
      color.ui = true;
      pull.rebase = true;
      gpg.format = "ssh";
      credential = {
        useHttpPath = true;
        credentialStore = "gpg";
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
    } // (if pkgs.stdenv.isDarwin then {
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    } else {});
  };
}
