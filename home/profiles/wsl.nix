{ pkgs, ... }:

{
  # socat is required by the wsl-proxy script (bin/wsl-proxy), which provides
  # on-demand localhost port forwarding from WSL2 to the Windows host.
  #
  # Usage:
  #   wsl-proxy start <port>   # forward localhost:<port> → windows-host:<port>
  #   wsl-proxy stop <port>    # stop forwarding <port>
  #   wsl-proxy list           # show all active forwards
  #   wsl-proxy status <port>  # check whether <port> is currently forwarded
  #
  # The Windows host IP is resolved dynamically via the default route on each
  # `start`, so it works correctly after WSL restarts.
  home.packages = with pkgs; [
    socat
  ];
}
