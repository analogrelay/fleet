{ pkgs, ... }:

{
  programs.git.extraConfig."gpg \"ssh\"".program =
    pkgs.lib.mkForce "/mnt/c/Users/ashleyst/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe";
}
