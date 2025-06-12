{ pkgs, lib, platform, wsl, ... }:

{
  imports = [ ]
    ++ (lib.optional (builtins.pathExists ./workstation.${platform}.nix)
      ./workstation.${platform}.nix);

  fonts = {
    packages = with pkgs; [
      monaspace
      nerd-fonts.monaspace
      nerd-fonts.zed-mono
    ];
  };

  home-manager.extraSpecialArgs = { role = "workstation"; };
}
