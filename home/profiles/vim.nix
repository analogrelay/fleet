{ config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  programs.vim.enable = true;
  home.file.".vimrc".source = fleetLink "config/vim/vimrc.vim";
  home.file.".ideavimrc".source = fleetLink "config/vim/ideavimrc.vim";
}
