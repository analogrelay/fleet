{ username, distro, lib, ... }:

{
  imports = [
  ] ++ lib.optional (builtins.pathExists ./${distro}.nix) [ ./${distro}.nix ];

  services.ssh-agent.enable = true;
  home.homeDirectory = "/home/${username}";
}