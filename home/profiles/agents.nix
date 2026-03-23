{ pkgs-unstable, ... }:

{
	programs.opencode = {
		package = pkgs-unstable.opencode;
		enable = true;
		settings = {
			theme = "gruvbox";
			plugin = [
				"opentmux@1.5.7"
				"@plannotator/opencode@0.14.4"
			];
		};
	};

	programs.claude-code = {
		package = pkgs-unstable.claude-code-bin;
		enable = true;
		settings = {
			statusLine = {
				type = "command";
				command = "npx -y ccstatusline@2.2.7";
				padding = 0;
			};
			env = {
			  CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1";
			};
		};
	};
}
