{ pkgs, config, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
    initLua = ''
      require("config.lazy")
      require("config.keymap")
      require("config.lsp")
      require("config.terminal")
    '';
  };
  home.file.".config/nvim/lua".source = fleetLink "config/nvim/lua";
}
