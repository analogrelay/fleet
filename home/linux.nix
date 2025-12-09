{
  username,
  distro,
  lib,
  pkgs,
  wsl,
  ...
}:

{
  imports = [
  ] ++ lib.optional (builtins.pathExists ./${distro}.nix) [ ./${distro}.nix ];

  # On WSL, we use the Windows-side SSH.
  services.ssh-agent.enable = !wsl;
  home.homeDirectory = "/home/${username}";
  home.packages = with pkgs; [
    pkg-config
    openssl
  ];
}
