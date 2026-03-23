{ pkgs, config, ... }:

let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in
{
  home.file.".config/tmux-powerline/config.sh".source = fleetLink "config/tmux-powerline/config.sh";
  programs.tmux = {
    enable = true;
		keyMode = "vi";
		shortcut = "a";
		plugins = with pkgs; [
			tmuxPlugins.sensible
			tmuxPlugins.gruvbox
			tmuxPlugins.tmux-powerline
			tmuxPlugins.vim-tmux-navigator
		];
		extraConfig = ''
			set -g set-titles
			set -g set-titles-string "#H::#S - #T"
		'';
  };
}
