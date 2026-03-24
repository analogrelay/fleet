{ lib, pkgs, config, tags, username, ... }:
let
  inherit (tags) os wsl role;
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
  commonImports = [ ../nix/modules/fleet/home.nix ./${os}.nix ]
    ++ (lib.optional (builtins.pathExists ./roles/${role}.nix)
      ./roles/${role}.nix)
    ++ (lib.optional (builtins.pathExists ./roles/${role}.${os}.nix)
      ./roles/${role}.${os}.nix) ++ [
				./profiles/agents.nix
        ./profiles/shell.nix
        ./profiles/git.nix
        ./profiles/nvim.nix
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

  home.stateVersion = "25.11";
  home.username = username;

  programs.home-manager.enable = true;
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
		fd
    wget
    curl
    nix-index
    kubectl
    k9s
    gh
    lazygit
    jq
    ripgrep
    powershell
  ];

  home.file = (lib.mapAttrs' (name: _: lib.nameValuePair ".local/bin/${name}" {
    source = fleetLink "bin/${name}";
  }) (lib.filterAttrs (name: type: type == "regular") (builtins.readDir ../bin))) // {
    ".config/eza".source = fleetLink "config/eza";
  };
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.cargo/bin" ];
  home.sessionVariables = { XDG_CONFIG_DIR = "$HOME/.config"; };
}
