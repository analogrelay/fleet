{ pkgs, tags, ... }:

{
  programs.vscode = if tags.os == "linux" then {
    enable = true;
    package = pkgs.vscode.fhs;
  } else
    { };
}
