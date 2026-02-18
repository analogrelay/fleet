{ pkgs, ... }:

{
  home.file.".config/copilot" = {
    source = ../../copilot;
    recursive = true;
  };
}
