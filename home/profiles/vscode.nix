{ pkgs, tags, ... }:

{
  programs.vscode = if tags.os == "linux" then {
    enable = true;
    package = if tags.platform == "nixos" then pkgs.vscode.fhs else pkgs.vscode;
  } else
    { };
}
