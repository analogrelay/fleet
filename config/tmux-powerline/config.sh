# Default configuration file for tmux-powerline.
Modeline {
 vi: foldmarker={,} foldmethod=marker foldlevel=0 tabstop=4 filetype=sh
}

General {
	# Show which segment fails and its exit code.
	export TMUX_POWERLINE_DEBUG_MODE_ENABLED="false"
	# Use patched font symbols.
	export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

	# The theme to use.
	export TMUX_POWERLINE_THEME="default"
	# Overlay directory to look for themes. There you can put your own themes outside the repo. Fallback will still be the "themes" directory in the repo.
	export TMUX_POWERLINE_DIR_USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/themes"
	# Overlay directory to look for segments. There you can put your own segments outside the repo. Fallback will still be the "segments" directory in the repo.
	export TMUX_POWERLINE_DIR_USER_SEGMENTS="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/segments"

	# The initial visibility of the status bar. Can be {"on, off"}.
	export TMUX_POWERLINE_STATUS_VISIBILITY="on"
	# The status bar refresh interval in seconds.
	# Note that events that force-refresh the status bar (such as window renaming) will ignore this.
	export TMUX_POWERLINE_STATUS_INTERVAL="1"
	# The location of the window list. Can be {"absolute-centre, centre, left, right"}.
	# Note that "absolute-centre" is only supported on `tmux -V` >= 3.2.
	export TMUX_POWERLINE_STATUS_JUSTIFICATION="centre"

	# The maximum length of the left status bar.
	export TMUX_POWERLINE_STATUS_LEFT_LENGTH="60"
	# The maximum length of the right status bar.
	export TMUX_POWERLINE_STATUS_RIGHT_LENGTH="90"

	# Uncomment these if you want to enable tmux bindings for muting (hiding) one of the status bars.
	# E.g. this example binding would mute the left status bar when pressing <prefix> followed by Ctrl-[
	#export TMUX_POWERLINE_MUTE_LEFT_KEYBINDING="C-["
	#export TMUX_POWERLINE_MUTE_RIGHT_KEYBINDING="C-]"
}

battery.sh {
	# How to display battery remaining. Can be {percentage, cute}.
	export TMUX_POWERLINE_SEG_BATTERY_TYPE="percentage"
	# How may hearts to show if cute indicators are used.
	export TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS="5"
}

hostname.sh {
	# Use short or long format for the hostname. Can be {"short, long"}.
	export TMUX_POWERLINE_SEG_HOSTNAME_FORMAT="short"
}

now_playing.sh {
	# Music player to use. Can be any of {audacious, banshee, cmus, apple_music, itunes, lastfm, mocp, mpd, mpd_simple, pithos, playerctl, rdio, rhythmbox, spotify, spotify_wine, file}.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_MUSIC_PLAYER="spotify"
	# File to be read in case the song is being read from a file
	export TMUX_POWERLINE_SEG_NOW_PLAYING_FILE_NAME=""
	# Maximum output length.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_MAX_LEN="40"
	# How to handle too long strings. Can be {trim, roll}.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_TRIM_METHOD="trim"
	# Charcters per second to roll if rolling trim method is used.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_ROLL_SPEED="2"
	
	# Hostname for MPD server in the format "[password@]host"
	export TMUX_POWERLINE_SEG_NOW_PLAYING_MPD_HOST="localhost"
	# Port the MPD server is running on.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_MPD_PORT="6600"
	# Song display format for mpd_simple. See mpc(1) for delimiters.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_MPD_SIMPLE_FORMAT="%artist% - %title%"
	# Song display format for playerctl. see "Format Strings" in playerctl(1).
	export TMUX_POWERLINE_SEG_NOW_PLAYING_PLAYERCTL_FORMAT="{{ artist }} - {{ title }}"
	# Song display format for rhythmbox. see "FORMATS" in rhythmbox-client(1).
	export TMUX_POWERLINE_SEG_NOW_PLAYING_RHYTHMBOX_FORMAT="%aa - %tt"
	
	# Last.fm
	# Set up steps for Last.fm
	# 1. Make sure jq(1) is installed on the system.
	# 2. Create a new API application at https://www.last.fm/api/account/create (name it tmux-powerline) and copy the API key and insert it below in the setting TMUX_POWERLINE_SEG_NOW_PLAYING_LASTFM_API_KEY
	# 3. Make sure the API can access your recently played song by going to you user privacy settings https://www.last.fm/settings/privacy and make sure "Hide recent listening information" is UNCHECKED.
	# Username for Last.fm if that music player is used.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_LASTFM_USERNAME=""
	# API Key for the API.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_LASTFM_API_KEY=""
	# How often in seconds to update the data from last.fm.
	export TMUX_POWERLINE_SEG_NOW_PLAYING_LASTFM_UPDATE_PERIOD="30"
	# Fancy char to display before now playing track
	export TMUX_POWERLINE_SEG_NOW_PLAYING_NOTE_CHAR="♫"
}

pwd.sh {
	# Maximum length of output.
	export TMUX_POWERLINE_SEG_PWD_MAX_LEN="40"
}

tmux_session_info.sh {
	# Session info format to feed into the command: tmux display-message -p
	# For example, if FORMAT is '[ #S ]', the command is: tmux display-message -p '[ #S ]'
	export TMUX_POWERLINE_SEG_TMUX_SESSION_INFO_FORMAT="#S:#I.#P"
}

vcs_branch.sh {
	# Max length of the branch name.
	export TMUX_POWERLINE_SEG_VCS_BRANCH_MAX_LEN="24"
}
