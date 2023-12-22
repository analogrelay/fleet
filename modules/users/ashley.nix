{ config, lib, pkgs, ... }:

{
    users.users.ashley = {
        uid = 1000;
        description = "Ashley Stanton-Nurse";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [ 
            "wheel" 
            "networkmanager" 
            "libvirtd"
            "docker"
            "share"
            "family"
        ];
        initialPassword = "pw123";
        openssh.authorizedKeys.keyFiles = [
            ../../keys/1password.pub
            ../../keys/jenova.pub
        ];
    };
}