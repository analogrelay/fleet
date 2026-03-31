# Expose the Windows host IP as WSL_HOST so scripts and tools
# (e.g. wsl-proxy, browser-open, X11 forwarding) can reach it
# without re-resolving on every call.

if is wsl; then
  export WSL_HOST="$(ip route show default | awk '{print $3}')"
fi
