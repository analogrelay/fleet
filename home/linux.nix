{
  username,
  distro,
  lib,
  pkgs,
  ...
}:

{
  imports = [
  ] ++ lib.optional (builtins.pathExists ./${distro}.nix) [ ./${distro}.nix ];

  services.ssh-agent.enable = true;
  home.homeDirectory = "/home/${username}";
  home.packages = with pkgs; [
    pkg-config
    openssl
  ];
}
