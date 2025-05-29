{ pkgs, os, ... }:

{
  programs.vscode = if os == "linux" then {
    enable = true;
    package = pkgs.vscode.fhs;
  } else
    { };
}
