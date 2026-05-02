#!/usr/bin/env bash
# remote-ban: Client-side remote ban management tool
# Communicates with remote-ban-server on target hosts via SSH.
set -euo pipefail

KEYS_DIR="${HOME}/.config/remote-ban/keys"
REMOTE_USER="remote-ban"
REMOTE_SERVER_PATH="/usr/local/bin/remote-ban-server"
REMOTE_CONFIG_DIR="/etc/remote-ban"
REMOTE_HOME="/var/lib/remote-ban"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "remote-ban: $*"; }

# SSH to the server using the provisioned key and run a command.
ssh_ban_cmd() {
  local addr="$1"
  shift
  local key_file="${KEYS_DIR}/${addr}"

  [[ -f "$key_file" ]] || die "no key found for '$addr'. Run 'remote-ban install $addr' first."

  # shellcheck disable=SC2029
  ssh -i "$key_file" \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    "${REMOTE_USER}@${addr}" \
    "$*"
}

# Ban an IP on a remote server.
cmd_ban() {
  local addr="${1:-}"
  local ip="${2:-}"
  local duration="${3:-}"
  [[ -n "$addr" ]] || die "usage: remote-ban ban <addr> <ip> <duration>"
  [[ -n "$ip" ]] || die "usage: remote-ban ban <addr> <ip> <duration>"
  [[ -n "$duration" ]] || die "usage: remote-ban ban <addr> <ip> <duration>"

  ssh_ban_cmd "$addr" "ban $ip $duration"
}

# Unban an IP (or all IPs) on a remote server.
cmd_unban() {
  local addr="${1:-}"
  local ip="${2:-}"
  [[ -n "$addr" ]] || die "usage: remote-ban unban <addr> <ip|all>"
  [[ -n "$ip" ]] || die "usage: remote-ban unban <addr> <ip|all>"

  if [[ "$ip" == "all" ]]; then
    ssh_ban_cmd "$addr" "unban-all"
  else
    ssh_ban_cmd "$addr" "unban $ip"
  fi
}

# List banned IPs on a remote server.
cmd_list() {
  local addr="${1:-}"
  [[ -n "$addr" ]] || die "usage: remote-ban list <addr>"

  ssh_ban_cmd "$addr" "list"
}

# Install remote-ban-server on a remote host.
cmd_install() {
  local addr="${1:-}"
  [[ -n "$addr" ]] || die "usage: remote-ban install <addr>"

  info "installing remote-ban-server on $addr..."

  # Locate the server script (bundled alongside this script in the package)
  local self_dir
  self_dir="$(dirname "$(readlink -f "$0")")"
  local server_script="${self_dir}/remote-ban-server"
  [[ -f "$server_script" ]] || die "cannot find remote-ban-server script at $server_script"

  # Prompt for trusted interfaces
  echo ""
  echo "Enter trusted network interfaces (space-separated)."
  echo "Traffic on these interfaces will NEVER be banned."
  echo "Examples: tailscale0, wg0, tun0"
  echo ""
  read -rp "Trusted interfaces (or empty for none): " trusted_ifaces_input

  info "deploying server script to $addr..."

  # Copy the server script to the remote host
  scp -q "$server_script" "${addr}:/tmp/remote-ban-server"

  # Run the installation steps on the remote host via SSH + sudo
  # shellcheck disable=SC2087
  ssh -t "$addr" bash -s <<INSTALL_SCRIPT
set -euo pipefail

echo "remote-ban-install: setting up on \$(hostname)..."

# Install the server script
sudo install -m 755 /tmp/remote-ban-server "$REMOTE_SERVER_PATH"
rm -f /tmp/remote-ban-server

# Create the remote-ban system user
if ! id "$REMOTE_USER" &>/dev/null; then
  sudo useradd \
    --system \
    --shell /usr/sbin/nologin \
    --home-dir "$REMOTE_HOME" \
    --create-home \
    "$REMOTE_USER"
  echo "remote-ban-install: created user $REMOTE_USER"
else
  echo "remote-ban-install: user $REMOTE_USER already exists"
fi

# Ensure .ssh directory exists
sudo mkdir -p "$REMOTE_HOME/.ssh"
sudo chown "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME/.ssh"
sudo chmod 700 "$REMOTE_HOME/.ssh"

# Write trusted interfaces config
sudo mkdir -p "$REMOTE_CONFIG_DIR"
sudo tee "$REMOTE_CONFIG_DIR/trusted-interfaces" > /dev/null <<'TRUSTED_EOF'
# Trusted interfaces — traffic on these interfaces is never banned.
# One interface name per line. Managed by remote-ban install.
TRUSTED_EOF

TRUSTED_IFACES="$trusted_ifaces_input"
for iface in \$TRUSTED_IFACES; do
  echo "\$iface" | sudo tee -a "$REMOTE_CONFIG_DIR/trusted-interfaces" > /dev/null
done
echo "remote-ban-install: wrote trusted interfaces config"

# Set up sudoers entry
sudo tee /etc/sudoers.d/remote-ban > /dev/null <<'SUDOERS_EOF'
# Allow remote-ban user to run remote-ban-server as root without password
remote-ban ALL=(root) NOPASSWD: /usr/local/bin/remote-ban-server *
remote-ban ALL=(root) NOPASSWD: /usr/local/bin/remote-ban-server
SUDOERS_EOF
sudo chmod 440 /etc/sudoers.d/remote-ban
echo "remote-ban-install: configured sudoers"

# Initialize iptables chains
sudo "$REMOTE_SERVER_PATH" init
echo "remote-ban-install: initialized iptables chains"

INSTALL_SCRIPT

  info "generating SSH keypair for $addr..."

  # Generate SSH keypair locally
  mkdir -p "$KEYS_DIR"
  local key_file="${KEYS_DIR}/${addr}"
  if [[ -f "$key_file" ]]; then
    info "key already exists at $key_file, backing up..."
    mv "$key_file" "${key_file}.bak.$(date +%s)"
    mv "${key_file}.pub" "${key_file}.pub.bak.$(date +%s)" 2>/dev/null || true
  fi
  ssh-keygen -t ed25519 -f "$key_file" -N "" -C "remote-ban@${addr}" -q

  info "deploying public key to $addr..."

  # Read the public key
  local pubkey
  pubkey=$(cat "${key_file}.pub")

  # Deploy authorized_keys with forced command
  # shellcheck disable=SC2087
  ssh "$addr" bash -s <<DEPLOY_KEY
set -euo pipefail

# Write the authorized_keys file with forced command restriction
echo 'command="sudo $REMOTE_SERVER_PATH --from-ssh",restrict $pubkey' | \
  sudo tee "$REMOTE_HOME/.ssh/authorized_keys" > /dev/null
sudo chown "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME/.ssh/authorized_keys"
sudo chmod 600 "$REMOTE_HOME/.ssh/authorized_keys"
echo "remote-ban-install: deployed authorized_keys"
DEPLOY_KEY

  info "verifying connection..."

  # Test the connection
  if ssh -i "$key_file" \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "${REMOTE_USER}@${addr}" "list" &>/dev/null; then
    info "verification successful!"
  else
    info "warning: verification failed. You may need to check SSH configuration on $addr."
  fi

  echo ""
  info "installation complete!"
  info "key stored at: $key_file"
  info ""
  info "usage:"
  info "  remote-ban ban $addr <ip> <duration>"
  info "  remote-ban unban $addr <ip>"
  info "  remote-ban unban $addr all"
  info "  remote-ban list $addr"
}

# Print usage information.
usage() {
  cat <<EOF
usage: remote-ban <command> [args...]

commands:
  install <addr>                 Set up remote-ban-server on a remote host
  ban <addr> <ip> <duration>     Ban an IP for <duration> seconds
  unban <addr> <ip>              Unban a specific IP
  unban <addr> all               Unban all IPs
  list <addr>                    List currently banned IPs

options:
  -h, --help                     Show this help message
EOF
}

# Main dispatch.
main() {
  local subcmd="${1:-}"

  case "$subcmd" in
    -h|--help|"")
      usage
      [[ -n "$subcmd" ]] && exit 0 || exit 1
      ;;
    install) shift; cmd_install "$@" ;;
    ban)     shift; cmd_ban "$@" ;;
    unban)   shift; cmd_unban "$@" ;;
    list)    shift; cmd_list "$@" ;;
    *)       die "unknown command: $subcmd. Run 'remote-ban --help' for usage." ;;
  esac
}

main "$@"
