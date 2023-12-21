{ config, lib, pkgs, ... }:

{
    users.users.mary = {
        uid = 1001;
        description = "Mary Stanton-Nurse";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ 
            "share"
            "family"
        ];
        initialPassword = "pw123";
        openssh.authorizedKeys.keyFiles = [
        ];
    };
}