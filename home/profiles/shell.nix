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
  };

  programs.starship = {
    enable = false;
    settings = {
      shell = {
        disabled = false;
      };
      custom = {
        arch = {
          command = "echo $(arch)";
          description = "Current Process CPU Architecture";
          when = "true";
          os = "macos";
          symbol = "🖥";
          format = "\\($symbol  $output\\)";
        };
      };
    };
  };
}