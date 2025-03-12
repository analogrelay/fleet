{ wsl, ... }:

{
  programs.git.extraConfig."gpg \"ssh\"".program = if wsl then "/mnt/c/Users/ashley/AppData/Local/1Password/app/8/op-ssh-sign-wsl" else "op-ssh-sign";
}
