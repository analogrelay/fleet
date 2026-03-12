{
  username,
  tags,
  ...
}:

{
  # On WSL, we use the Windows-side SSH.
  services.ssh-agent.enable = !tags.wsl;
  home.homeDirectory = "/home/${username}";
}
