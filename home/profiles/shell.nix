{ ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
    };

    initExtra = ''
      # Mark all files with no extension in the 'functions' directory as autoloaded
      FUNCS_TO_AUTOLOAD=("''${(@f)$(find "$HOME/.config/zsh/functions" \! -name "*.*")}")
      for func in $FUNCS_TO_AUTOLOAD; do
          autoload $func
      done

      # Load Git keys
      if [ -f ~/.ssh/git_signing ]; then
        ssh-add ~/.ssh/git_signing
      fi
    '';

    shellAliases = {
      ls = "eza";
      cat = "bat";
    };

    profileExtra = ''
    '';
  };
  home.file.".config/zsh/functions" = {
    source = ../../zsh/functions;
    recursive = true;
  };

  programs.bash = {
    enable = true;
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ../analogposh.omp.json));
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