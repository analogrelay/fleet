{ lib, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    enableCompletion = true;
    initContent = lib.mkOrder 1000 "source ~/.config/zsh/analogzsh.zsh";
  };
  home.file.".config/zsh/analogzsh.zsh" = { source = ../../zsh/.zshrc; };
  home.file.".config/zsh/functions" = {
    source = ../../zsh/functions;
    recursive = true;
  };
  home.file.".config/analogposh.omp.json" = {
    source = ../analogposh.omp.json;
    recursive = true;
  };

  programs.bash = { enable = true; };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext
      (builtins.readFile ../analogposh.omp.json));
  };
}
