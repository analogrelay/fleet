#!/usr/bin/env bash
# remote-ban-server: Server-side IP ban management via iptables
# Deployed to remote hosts by `remote-ban install`. Portable (no Nix deps).
set -euo pipefail

CHAIN="REMOTE_BAN"
TRUSTED_IFACES_FILE="/etc/remote-ban/trusted-interfaces"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "remote-ban-server: $*"; }

# Detect if an IP is IPv4 or IPv6. Returns "4" or "6".
ip_version() {
  local ip="$1"
  if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
    echo "4"
  elif [[ "$ip" =~ : ]]; then
    echo "6"
  else
    die "invalid IP address: $ip"
  fi
}

# Return the appropriate iptables command for the given IP version.
ipt_cmd() {
  local ver="$1"
  if [[ "$ver" == "4" ]]; then
    echo "iptables"
  else
    echo "ip6tables"
  fi
}

# Sanitize an IP for use in systemd unit names (replace special chars).
sanitize_ip() {
  local ip="$1"
  echo "$ip" | tr ':/' '--'
}

# Load trusted interfaces from config file.
load_trusted_interfaces() {
  if [[ -f "$TRUSTED_IFACES_FILE" ]]; then
    grep -v '^\s*#' "$TRUSTED_IFACES_FILE" | grep -v '^\s*$' || true
  fi
}

# Check if an IP is assigned to any trusted interface.
ip_on_trusted_interface() {
  local target_ip="$1"
  local ifaces
  ifaces=$(load_trusted_interfaces)

  if [[ -z "$ifaces" ]]; then
    return 1
  fi

  while IFS= read -r iface; do
    # Check if the target IP is assigned to this interface
    if ip addr show dev "$iface" 2>/dev/null | grep -qw "$target_ip"; then
      return 0
    fi
  done <<< "$ifaces"

  return 1
}

# Ensure the REMOTE_BAN chain exists and is wired into INPUT.
ensure_chain() {
  local ipt="$1"

  # Create chain if it doesn't exist
  if ! $ipt -L "$CHAIN" -n &>/dev/null; then
    $ipt -N "$CHAIN"
    info "created $CHAIN chain ($ipt)"
  fi

  # Ensure INPUT jumps to our chain (idempotent)
  if ! $ipt -C INPUT -j "$CHAIN" &>/dev/null; then
    $ipt -I INPUT -j "$CHAIN"
    info "inserted INPUT -> $CHAIN jump ($ipt)"
  fi
}

# Add RETURN rules for trusted interfaces at the top of the chain.
setup_trusted_returns() {
  local ipt="$1"
  local ifaces
  ifaces=$(load_trusted_interfaces)

  if [[ -z "$ifaces" ]]; then
    return 0
  fi

  while IFS= read -r iface; do
    if ! $ipt -C "$CHAIN" -i "$iface" -j RETURN &>/dev/null; then
      $ipt -I "$CHAIN" -i "$iface" -j RETURN
      info "added RETURN rule for trusted interface $iface ($ipt)"
    fi
  done <<< "$ifaces"
}

# Initialize the chain and trusted interface rules.
cmd_init() {
  ensure_chain iptables
  ensure_chain ip6tables
  setup_trusted_returns iptables
  setup_trusted_returns ip6tables
  info "initialization complete"
}

# Ban an IP for a given duration (seconds).
cmd_ban() {
  local ip="${1:-}"
  local duration="${2:-}"
  [[ -n "$ip" ]] || die "usage: remote-ban-server ban <ip> <duration>"
  [[ -n "$duration" ]] || die "usage: remote-ban-server ban <ip> <duration>"
  [[ "$duration" =~ ^[0-9]+$ ]] || die "duration must be a positive integer (seconds)"

  if ip_on_trusted_interface "$ip"; then
    die "refusing to ban $ip: address is assigned to a trusted interface"
  fi

  local ver
  ver=$(ip_version "$ip")
  local ipt
  ipt=$(ipt_cmd "$ver")

  ensure_chain "$ipt"
  setup_trusted_returns "$ipt"

  # Check if already banned
  if $ipt -C "$CHAIN" -s "$ip" -j DROP &>/dev/null; then
    # Already banned — remove existing rule and timer, then re-add with new duration
    $ipt -D "$CHAIN" -s "$ip" -j DROP
    cancel_timer "$ip"
    info "updating existing ban for $ip"
  fi

  # Add the ban rule (append after RETURN rules)
  $ipt -A "$CHAIN" -s "$ip" -j DROP
  info "banned $ip ($ipt) for ${duration}s"

  # Schedule auto-unban
  local sanitized
  sanitized=$(sanitize_ip "$ip")
  local unit_name="remote-ban-expire-${sanitized}"

  systemd-run \
    --unit="$unit_name" \
    --on-active="${duration}s" \
    --description="Auto-unban $ip after ${duration}s" \
    /usr/local/bin/remote-ban-server unban "$ip" &>/dev/null

  info "scheduled auto-unban in ${duration}s (timer: $unit_name)"
}

# Unban a specific IP.
cmd_unban() {
  local ip="${1:-}"
  [[ -n "$ip" ]] || die "usage: remote-ban-server unban <ip>"

  local ver
  ver=$(ip_version "$ip")
  local ipt
  ipt=$(ipt_cmd "$ver")

  ensure_chain "$ipt"

  # Remove all matching rules for this IP
  while $ipt -D "$CHAIN" -s "$ip" -j DROP &>/dev/null; do
    true
  done

  cancel_timer "$ip"
  info "unbanned $ip ($ipt)"
}

# Unban all IPs (flush ban rules, preserve trusted interface RETURN rules).
cmd_unban_all() {
  # Flush and rebuild: flush the chain, then re-add trusted interface rules
  for ipt in iptables ip6tables; do
    ensure_chain "$ipt"
    $ipt -F "$CHAIN"
    setup_trusted_returns "$ipt"
    info "flushed all bans ($ipt)"
  done

  # Cancel all pending expiry timers
  cancel_all_timers
  info "all bans removed"
}

# List all banned IPs.
cmd_list() {
  for ipt in iptables ip6tables; do
    if ! $ipt -L "$CHAIN" -n &>/dev/null; then
      continue
    fi

    local label
    if [[ "$ipt" == "iptables" ]]; then
      label="IPv4"
    else
      label="IPv6"
    fi

    echo "=== $label Bans ==="
    # Parse iptables output: show only DROP rules (skip RETURN rules for trusted ifaces)
    $ipt -L "$CHAIN" -n --line-numbers 2>/dev/null | \
      awk 'NR<=2 {next} /DROP/ {print $0}' || true
    echo ""
  done

  # Show pending expiry timers
  echo "=== Pending Expiry Timers ==="
  systemctl list-timers 'remote-ban-expire-*' --no-pager 2>/dev/null || echo "(none)"
}

# Cancel the expiry timer for a specific IP.
cancel_timer() {
  local ip="$1"
  local sanitized
  sanitized=$(sanitize_ip "$ip")
  local unit_name="remote-ban-expire-${sanitized}"

  # Stop the timer if it exists (ignore errors if it doesn't)
  systemctl stop "${unit_name}.timer" &>/dev/null || true
  systemctl stop "${unit_name}.service" &>/dev/null || true
}

# Cancel all remote-ban expiry timers.
cancel_all_timers() {
  local timers
  timers=$(systemctl list-units --type=timer --no-legend --no-pager 2>/dev/null | \
    awk '/remote-ban-expire-/ {print $1}') || true

  if [[ -n "$timers" ]]; then
    while IFS= read -r timer; do
      systemctl stop "$timer" &>/dev/null || true
      local service="${timer%.timer}.service"
      systemctl stop "$service" &>/dev/null || true
    done <<< "$timers"
    info "cancelled all expiry timers"
  fi
}

# Entry point when called from SSH forced command.
cmd_from_ssh() {
  local orig_cmd="${SSH_ORIGINAL_COMMAND:-}"
  [[ -n "$orig_cmd" ]] || die "no command provided (SSH_ORIGINAL_COMMAND is empty)"

  # Parse the original command into an array
  # shellcheck disable=SC2086
  set -- $orig_cmd
  local subcmd="${1:-}"
  shift || true

  case "$subcmd" in
    ban)     cmd_ban "$@" ;;
    unban)   cmd_unban "$@" ;;
    unban-all) cmd_unban_all ;;
    list)    cmd_list ;;
    *)       die "unknown command from SSH: $subcmd" ;;
  esac
}

# Main dispatch.
main() {
  local subcmd="${1:-}"
  [[ -n "$subcmd" ]] || die "usage: remote-ban-server <command> [args...]
commands: init, ban, unban, unban-all, list, --from-ssh"

  shift
  case "$subcmd" in
    init)      cmd_init ;;
    ban)       cmd_ban "$@" ;;
    unban)     cmd_unban "$@" ;;
    unban-all) cmd_unban_all ;;
    list)      cmd_list ;;
    --from-ssh) cmd_from_ssh ;;
    *)         die "unknown command: $subcmd" ;;
  esac
}

main "$@"
