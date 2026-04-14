{
  tags,
  pkgs,
  lib,
  username,
  ...
}:

{
  programs.git.settings =
    if tags.wsl then
      {
        "gpg \"ssh\"".program = pkgs.lib.mkDefault "/mnt/c/Program Files/1Password/app/8/op-ssh-sign-wsl";
        core.sshCommand = "ssh.exe";
      }
    else
      {
        "gpg \"ssh\"".program = "op-ssh-sign";
      };

  # lazy.nvim hard-codes GIT_SSH_COMMAND="ssh -oBatchMode=yes", overriding
  # core.sshCommand. Setting GIT_SSH_COMMAND in the environment ensures the
  # Windows SSH binary (with 1Password agent access) is used everywhere.
  home.sessionVariables = lib.mkIf tags.wsl {
    GIT_SSH_COMMAND = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
  };

  home.packages = with pkgs; [
    clang
    linuxPackages.perf
    valgrind
  ];
}
