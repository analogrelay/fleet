{ pkgs, wsl, role, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = pkgs.lib.mkDefault "Ashley Stanton-Nurse";
        email = pkgs.lib.mkDefault "git@analogrelay.net";
      };
      url = {
        "ssh://git@github.com/" = { insteadOf = "https://github.com/"; };
      };
      init.defaultBranch = "main";
      color.ui = true;
      pull.rebase = true;
      gpg.format = "ssh";
      credential = {
        useHttpPath = true;
        credentialStore = "gpg";
        helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      };
    };
    signing = {
      key = builtins.readFile ../../keys/gitSigning.pub;
      signByDefault = true;
    };
    includes = [
      { path = "~/.config/git/config.d/base.gitconfig"; }
      { path = "~/.config/git/config.d/local.gitconfig"; }
    ];
  };
}
