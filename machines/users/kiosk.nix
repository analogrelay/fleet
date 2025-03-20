{ pkgs, lib, ... }:

{
    users.users.kiosk = {
        uid = 2001;
        description = "Kiosk User";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ 
            "share"
            "unattend"
        ];
        initialHashedPassword = "$y$j9T$q0Sl6jJo8lxrJkXt3p2yq0$c0rXC6qssKoj2GSPtmrgOnbwXOEcUe8qLxChOJrP0s.";
        openssh.authorizedKeys.keyFiles = [
        ];
    };
    home-manager.users.kiosk = {
        home.username = lib.mkForce "kiosk";
        home.homeDirectory = lib.mkForce "/home/kiosk";
        imports = [
            ../../home
            ({ config, ...}: {
                # Symlink retroarch cores directory to kiosk's home directory
                home.file.".config/retroarch/cores".source = config.lib.file.mkOutOfStoreSymlink "/run/current-system/sw/lib/retroarch/cores";
                home.file.".config/autostart/es-de.desktop".source = config.lib.file.mkOutOfStoreSymlink "/run/current-system/sw/share/applications/es-de.desktop";
            })
        ];
    };
}
