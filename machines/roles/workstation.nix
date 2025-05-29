{ pkgs, lib, platform, wsl, ... }:

{
  imports = [ ]
    ++ (lib.optional (builtins.pathExists ./workstation.${platform}.nix)
      ./workstation.${platform}.nix);

  fonts = {
    packages = with pkgs; [
      monaspace
      (nerdfonts.override { fonts = [ "Monaspace" ]; })
    ];
  };

  home-manager.extraSpecialArgs = { role = "workstation"; };
}
