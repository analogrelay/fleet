{ config, lib, pkgs, ... }:

{
    programs.zsh.enable = true;

    users.users = {
        ashley = {
            description = "Ashley Stanton-Nurse";
            shell = pkgs.zsh;
            isNormalUser = true;
            extraGroups = [ 
                "wheel" 
                "networkmanager" 
                "libvirtd"
                "docker"
            ];
            initialPassword = "pw123";
            openssh.authorizedKeys.keyFiles = [
                ../keys/local-server-admin.pub
            ];
        };
    };
}