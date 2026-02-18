{ lib, pkgs, config, role, os, wsl, username, ... }:
let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
  commonImports = [ ./fleet.nix ./${os}.nix ]
    ++ (lib.optional (builtins.pathExists ./roles/${role}.nix)
      ./roles/${role}.nix)
    ++ (lib.optional (builtins.pathExists ./roles/${role}.${os}.nix)
      ./roles/${role}.${os}.nix) ++ [
        ./profiles/shell.nix
        ./profiles/git.nix
        ./profiles/vim.nix
        ./profiles/ssh.nix
        ./profiles/tmux.nix
        ./profiles/gaming.nix

        ./users/${username}.nix
      ];
  nonWslImports = if (!wsl) then [ ./profiles/vscode.nix ] else [ ];
  wslImports = if (wsl) then [ ./profiles/wsl.nix ] else [ ];
  allImports = commonImports ++ nonWslImports ++ wslImports;
in {
  imports = allImports;

  home.stateVersion = "24.05";
  home.username = username;

  programs.home-manager.enable = true;
  programs.ssh.enable = true;
  programs.fzf.enable = true;
  programs.gpg.enable = true;
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };
  programs.bat.enable = true;
  programs.password-store.enable = true;
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    dos2unix
    direnv
    _1password-cli
    nixfmt-rfc-style
    zip
    unzip
  ];

  home.file.".local/bin".source = fleetLink "bin";
  home.file.".config/eza".source = fleetLink "config/eza";
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.cargo/bin" ];
  home.sessionVariables = { XDG_CONFIG_DIR = "$HOME/.config"; };
}
