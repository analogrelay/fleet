{ wsl, ... }:

{
  programs.git.extraConfig = if wsl then {
    "gpg \"ssh\"".program = "/mnt/c/Users/ashley/AppData/Local/1Password/app/8/op-ssh-sign-wsl";
    core.sshCommand = "ssh.exe";
  } else {
    "gpg \"ssh\"".program = "op-ssh-sign";
  };

  home.packages = with pkgs; [
      microsoft-edge
  ];
}
