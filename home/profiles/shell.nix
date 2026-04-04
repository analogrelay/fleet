{ lib, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;
    initContent = lib.mkOrder 1000 "source ~/.config/zsh/analogzsh.zsh";
  };
  home.file.".config/zsh/analogzsh.zsh".source = fleetLink "config/zsh/analogzsh.zsh";
  home.file.".config/zsh/functions".source = fleetLink "config/zsh/functions";
  home.file.".config/zsh/profile.d".source = fleetLink "config/zsh/profile.d";
  home.file.".config/analogposh.omp.json".source =
    fleetLink "config/analogposh.omp.json";

  programs.bash = { enable = true; };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    configFile = ../../config/analoglite.omp.json;
  };
}
