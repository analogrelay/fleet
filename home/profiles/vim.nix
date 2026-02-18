{ ... }:

{
  programs.vim.enable = true;
  home.file.".vimrc".source = ./vim/vimrc.vim;
  home.file.".ideavimrc".source = ./vim/ideavimrc.vim;
}
