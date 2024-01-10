{ lib, ... }:

{
    programs.zsh.shellAliases = {
        "ssh" = "ssh.exe";
        "ssh-add" = "ssh-add.exe";
    };
}