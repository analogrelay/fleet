{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gopls
    omnisharp-roslyn
    typescript-language-server
    typescript
    pyright
    nil
    lua-language-server
  ];
}
