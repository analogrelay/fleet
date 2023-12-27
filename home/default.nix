{ role, os, ... }:

{
  imports = [
    ./${os}.nix
    ./roles/${role}.nix
    ./roles/${role}.${os}.nix

    ./profiles/git.nix
    ./profiles/vim.nix
    ./profiles/ssh.nix
  ];

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
  programs.ssh.enable = true;
}