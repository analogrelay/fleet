{ pkgs, wsl, role, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in

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
        helper = if (wsl) then
          "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe"
        else "${pkgs.git-credential-manager}/bin/git-credential-manager";
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
  home.file.".config/git/config.d".source = fleetLink "config/git/config.d";
}
