{ pkgs, ... }:

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
}
