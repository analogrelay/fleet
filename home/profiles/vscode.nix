{ pkgs, ... }:

let
  nixpkgs-extensions = with pkgs.vscode-extensions; [
    vscodevim.vim
    github.copilot
    jnoortheen.nix-ide
    ms-vscode-remote.remote-ssh
  ];
  marketplace-extensions = with pkgs.vscode-marketplace; [
    robbowen.synthwave-vscode
    ms-vscode.remote-explorer
    ms-vscode-remote.remote-ssh-edit
  ];
in
{
  home.packages = with pkgs; [
    nil
  ];

  programs.vscode = {
    enable = true;
    extensions = nixpkgs-extensions ++ marketplace-extensions;
    userSettings = {
      "workbench.colorTheme" = "SynthWave '84";
      "terminal.integrated.fontFamily" = "'Monaspace Krypton', Consolas, 'Courier New', monospace";
      "editor.fontFamily" = "'Monaspace Argon', Consolas, 'Courier New', monospace";
      "editor.codeLensFontFamily" = "'Monaspace Krypton', Consolas, 'Courier New', monospace";
      "editor.tokenColorCustomizations" = {
        "textMateRules" = [
          {
            "scope" = ["storage" "keyword" "meta.macro.rules.rust" "meta.tag.table.toml"];
            "settings" = {
                "fontStyle" = "italic bold";
            };
          }
          {
            "scope" = ["keyword.operator" "punctuation"];
            "settings" = {
                "fontStyle" = "bold";
            };
          }
          {
            "scope" = ["meta.function.definition" "meta.attribute" "keyword.key.toml"];
            "settings" = {
                "fontStyle" = "italic";
            };
          }
          {
            "scope" = ["meta.interpolation"];
            "settings" = {
                "fontStyle" = "bold";
                "foreground" = "#FEDE5D";
            };
          }
        ];
      };
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
    };
  };
}
