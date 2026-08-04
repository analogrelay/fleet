{ pkgs, pkgs-unstable, config, ... }:

let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  home.packages = [ pkgs.plannotator pkgs-unstable.github-copilot-cli ];

  programs.opencode = {
    package = pkgs-unstable.opencode;
    enable = true;
    web.enable = true;
    tui = { theme = "gruvbox"; };
    settings = {
      mcp = {
        linear = {
          type = "remote";
          url = "https://mcp.linear.app/mcp";
        };
      };
      plugin = [ "opentmux@1.5.7" "@plannotator/opencode@0.25.1" ];
    };
  };

  programs.claude-code = {
    package = pkgs.claude-code;
    enable = true;
    settings = {
      enabledPlugins = { "plannotator@plannotator" = true; };
      statusLine = {
        type = "command";
        command = "npx -y ccstatusline@2.2.7";
        padding = 0;
      };
      env = { CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1"; };
    };
  };

  # Link relevant agent instructions into place
  home.file.".copilot/copilot-instructions.md".source =
    fleetLink "config/agents/AGENTS.md";
  home.file.".agents/skills".source = fleetLink "config/agents/skills";
}
