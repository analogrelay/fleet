{
  username,
  lib,
  pkgs,
  wsl,
  ...
}:

{
  # On WSL, we use the Windows-side SSH.
  services.ssh-agent.enable = !wsl;
  home.homeDirectory = "/home/${username}";
  home.packages = with pkgs; [
    pkg-config
    openssl
  ];
}
