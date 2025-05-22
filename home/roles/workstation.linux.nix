{
  wsl,
  pkgs,
  username,
  ...
}:

{
  programs.git.extraConfig =
    if wsl then
      {
        "gpg \"ssh\"".program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
        core.sshCommand = "ssh.exe";
      }
    else
      { "gpg \"ssh\"".program = "op-ssh-sign"; };

  home.packages = with pkgs; [ microsoft-edge ];
}
