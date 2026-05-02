#!/usr/bin/env bash
# remote-ban: Client-side remote ban management tool
# Communicates with remote-ban-server on target hosts via SSH.
set -euo pipefail

KEYS_DIR="${HOME}/.config/remote-ban/keys"
REMOTE_USER="remote-ban"
REMOTE_SERVER_PATH="/usr/local/bin/remote-ban-server"
REMOTE_CONFIG_DIR="/etc/remote-ban"
REMOTE_HOME="/var/lib/remote-ban"

# Set by Nix wrapper via --set; fallback to relative path for non-Nix usage.
REMOTE_BAN_SERVER_SCRIPT="${REMOTE_BAN_SERVER_SCRIPT:-}"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "remote-ban: $*"; }

# Validate an interface name (alphanumeric, dash, underscore, dot).
validate_iface_name() {
  local name="$1"
  if [[ ! "$name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    die "invalid interface name: '$name' (must be alphanumeric, dash, underscore, dot)"
  fi
}

# Locate the portable server script for deployment.
find_server_script() {
  if [[ -n "$REMOTE_BAN_SERVER_SCRIPT" && -f "$REMOTE_BAN_SERVER_SCRIPT" ]]; then
    echo "$REMOTE_BAN_SERVER_SCRIPT"
    return
  fi
  # Fallback: look relative to this script
  local self_dir
  self_dir="$(dirname "$(readlink -f "$0")")"
  local candidates=(
    "${self_dir}/../share/remote-ban/remote-ban-server"
    "${self_dir}/remote-ban-server"
  )
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
  die "cannot find remote-ban-server script. Searched: ${candidates[*]}"
}

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

  local server_script
  server_script=$(find_server_script)

  # Prompt for trusted interfaces
  echo ""
  echo "Enter trusted network interfaces (space-separated)."
  echo "Traffic on these interfaces will NEVER be banned."
  echo "Examples: tailscale0, wg0, tun0"
  echo ""
  read -rp "Trusted interfaces (or empty for none): " trusted_ifaces_input

  # Validate interface names before sending to remote
  local -a ifaces=()
  if [[ -n "$trusted_ifaces_input" ]]; then
    read -ra ifaces <<< "$trusted_ifaces_input"
    for iface in "${ifaces[@]}"; do
      validate_iface_name "$iface"
    done
  fi

  info "deploying server script to $addr..."

  # Use a private temp file on the remote host to avoid TOCTOU races
  local remote_tmp
  remote_tmp=$(ssh "$addr" "mktemp /tmp/remote-ban-server.XXXXXXXX")
  scp -q "$server_script" "${addr}:${remote_tmp}"

  # Run the installation steps on the remote host via SSH + sudo.
  # All variable data is passed via stdin/environment, not interpolated into shell code.
  ssh -t "$addr" bash -s -- "$remote_tmp" <<'INSTALL_SCRIPT'
set -euo pipefail

REMOTE_TMP="$1"
REMOTE_USER="remote-ban"
REMOTE_SERVER_PATH="/usr/local/bin/remote-ban-server"
REMOTE_CONFIG_DIR="/etc/remote-ban"
REMOTE_HOME="/var/lib/remote-ban"

echo "remote-ban-install: setting up on $(hostname)..."

sudo install -m 755 "$REMOTE_TMP" "$REMOTE_SERVER_PATH"
rm -f "$REMOTE_TMP"

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

sudo mkdir -p "$REMOTE_HOME/.ssh"
sudo chown "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME/.ssh"
sudo chmod 700 "$REMOTE_HOME/.ssh"

sudo mkdir -p "$REMOTE_CONFIG_DIR"
printf '%s\n' '# Trusted interfaces — traffic on these interfaces is never banned.' \
  '# One interface name per line. Managed by remote-ban install.' | \
  sudo tee "$REMOTE_CONFIG_DIR/trusted-interfaces" > /dev/null
echo "remote-ban-install: wrote trusted interfaces header"

# Restrict sudoers to only allow the --from-ssh entry point
sudo tee /etc/sudoers.d/remote-ban > /dev/null <<'SUDOERS_EOF'
# Allow remote-ban user to run remote-ban-server --from-ssh as root
remote-ban ALL=(root) NOPASSWD: /usr/local/bin/remote-ban-server --from-ssh
SUDOERS_EOF
sudo chmod 440 /etc/sudoers.d/remote-ban
echo "remote-ban-install: configured sudoers"

sudo "$REMOTE_SERVER_PATH" init
echo "remote-ban-install: initialized iptables chains"
INSTALL_SCRIPT

  # Write trusted interfaces via a separate, safe step (no shell interpolation)
  if [[ ${#ifaces[@]} -gt 0 ]]; then
    printf '%s\n' "${ifaces[@]}" | \
      ssh "$addr" "sudo tee -a /etc/remote-ban/trusted-interfaces > /dev/null"
    info "wrote ${#ifaces[@]} trusted interface(s) to config"
  fi

  info "generating SSH keypair for $addr..."

  mkdir -p "$KEYS_DIR"
  chmod 700 "$KEYS_DIR"
  local key_file="${KEYS_DIR}/${addr}"
  if [[ -f "$key_file" ]]; then
    info "key already exists at $key_file, backing up..."
    mv "$key_file" "${key_file}.bak.$(date +%s)"
    mv "${key_file}.pub" "${key_file}.pub.bak.$(date +%s)" 2>/dev/null || true
  fi
  ssh-keygen -t ed25519 -f "$key_file" -N "" -C "remote-ban@${addr}" -q

  info "deploying public key to $addr..."

  local pubkey
  pubkey=$(cat "${key_file}.pub")

  # Deploy authorized_keys — pass the public key via stdin to avoid injection
  echo "$pubkey" | ssh "$addr" bash -s <<'DEPLOY_KEY'
set -euo pipefail
REMOTE_USER="remote-ban"
REMOTE_HOME="/var/lib/remote-ban"
REMOTE_SERVER_PATH="/usr/local/bin/remote-ban-server"

# Read the public key from stdin
read -r pubkey

# Build the authorized_keys entry with forced command + restrict
printf 'command="sudo %s --from-ssh",restrict %s\n' "$REMOTE_SERVER_PATH" "$pubkey" | \
  sudo tee "$REMOTE_HOME/.ssh/authorized_keys" > /dev/null
sudo chown "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME/.ssh/authorized_keys"
sudo chmod 600 "$REMOTE_HOME/.ssh/authorized_keys"
echo "remote-ban-install: deployed authorized_keys"
DEPLOY_KEY

  info "verifying connection..."

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
