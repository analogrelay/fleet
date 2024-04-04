{ ... }:

{
  programs.git = {
    extraConfig = {
      "gpg \"ssh\"".program = "/mnt/c/Program Files/1Password/app/8/op-ssh-sign.exe";
      core.sshCommand = "ssh.exe";
    };
  };
}
