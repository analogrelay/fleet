# Maintain ~/.ssh/auth_socket as a stable symlink so that SSH_AUTH_SOCK
# survives tmux detach → SSH disconnect → reconnect → reattach cycles.

_setup_ssh_auth_socket() {
  local target=""
  local stable="$HOME/.ssh/auth_socket"

  if [[ -n "$SSH_CONNECTION" && -n "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$stable" ]]; then
    # Remote session: point at the forwarded agent socket.
    target="$SSH_AUTH_SOCK"
  else
    # Local session: look for the 1Password agent.
    local op_darwin="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    local op_linux="$HOME/.1password/agent.sock"

    if [[ -S "$op_darwin" ]]; then
      target="$op_darwin"
    elif [[ -S "$op_linux" ]]; then
      target="$op_linux"
    elif [[ -n "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$stable" ]]; then
      # Fall back to whatever agent is already running (e.g. ssh-agent service).
      target="$SSH_AUTH_SOCK"
    fi
  fi

  if [[ -n "$target" ]]; then
    ln -snf "$target" "$stable"
    export SSH_AUTH_SOCK="$stable"
  elif [[ -S "$stable" ]]; then
    # Symlink already exists and points somewhere; just adopt it.
    export SSH_AUTH_SOCK="$stable"
  fi
}

_setup_ssh_auth_socket
