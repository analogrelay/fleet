{ lib, config, tags, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";

in {
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;
    oh-my-zsh = {
      enable = true;
      custom = "${config.home.homeDirectory}/.config/zsh/oh-my-zsh";
      plugins = [
        "1pssh"
        "direnv"
        "docker"
        "eza"
        "fzf"
        "gh"
        "git"
        "history"
        "jj"
        "rust"
        "ssh"
        "sudo"
      ] ++ (if (tags.os == "darwin") then [ "macos" ] else [ ])
        ++ (if (tags.os == "linux") then [ "ufw" ] else [ ]);
      theme = "analogshell";
    };
  };
  home.file.".config/zsh/oh-my-zsh".source = fleetLink "config/zsh/oh-my-zsh";

  programs.bash = { enable = true; };

  programs.oh-my-posh = {
    enable = false;
    enableZshIntegration = true;
    enableBashIntegration = true;
    configFile = ../../config/analoglite.omp.json;
  };
}
