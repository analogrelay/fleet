{ ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;
  };
  home.file.".config/zsh/functions" = {
    source = ../../zsh/functions;
    recursive = true;
  };
  home.file.".config/analogposh.omp.json" = {
    source = ../analogposh.omp.json;
    recursive = true;
  };

  programs.bash = {
    enable = true;
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
}
