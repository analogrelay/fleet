#!/usr/bin/env bash
# remote-ban-server: Server-side IP ban management via iptables
# Deployed to remote hosts by `remote-ban install`. Portable (no Nix deps).
set -euo pipefail

CHAIN="REMOTE_BAN"
TRUSTED_IFACES_FILE="/etc/remote-ban/trusted-interfaces"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "remote-ban-server: $*"; }

# Strict IPv4 validation: x.x.x.x or x.x.x.x/N
is_ipv4() {
  local ip="$1"
  local cidr_re='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})(/([0-9]{1,2}))?$'
  if [[ ! "$ip" =~ $cidr_re ]]; then
    return 1
  fi
  local i
  for i in "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; do
    if (( i > 255 )); then return 1; fi
  done
  if [[ -n "${BASH_REMATCH[6]}" ]] && (( BASH_REMATCH[6] > 32 )); then
    return 1
  fi
  return 0
}

# Strict IPv6 validation: hex groups with colons, optional /prefix
is_ipv6() {
  local ip="$1"
  local addr="${ip%%/*}"
  local prefix="${ip#*/}"
  # Must contain at least one colon, only hex digits, colons, and dots (for mapped v4)
  if [[ ! "$addr" =~ ^[0-9a-fA-F:]+([.][0-9]+)*$ ]]; then
    return 1
  fi
  if [[ ! "$addr" == *:* ]]; then
    return 1
  fi
  if [[ "$ip" == */* ]]; then
    if [[ ! "$prefix" =~ ^[0-9]+$ ]] || (( prefix > 128 )); then
      return 1
    fi
  fi
  return 0
}

# Validate and detect IP version. Returns "4" or "6".
ip_version() {
  local ip="$1"
  if is_ipv4 "$ip"; then
    echo "4"
  elif is_ipv6 "$ip"; then
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
  echo "$ip" | tr ':./' '---'
}

# Load trusted interfaces from config file.
load_trusted_interfaces() {
  if [[ -f "$TRUSTED_IFACES_FILE" ]]; then
    grep -v '^\s*#' "$TRUSTED_IFACES_FILE" | grep -v '^\s*$' || true
  fi
}

# Check if an IP is assigned to any trusted interface using structured output.
ip_on_trusted_interface() {
  local target_ip="$1"
  # Strip CIDR prefix for comparison
  local bare_ip="${target_ip%%/*}"
  local ifaces
  ifaces=$(load_trusted_interfaces)

  if [[ -z "$ifaces" ]]; then
    return 1
  fi

  while IFS= read -r iface; do
    # Use structured `ip -o addr` output for reliable matching.
    # Format: "idx: iface    inet[6] addr/prefix ..."
    while IFS= read -r line; do
      local addr
      addr=$(echo "$line" | awk '{print $4}')
      addr="${addr%%/*}"
      if [[ "$addr" == "$bare_ip" ]]; then
        return 0
      fi
    done < <(ip -o addr show dev "$iface" 2>/dev/null || true)
  done <<< "$ifaces"

  return 1
}

# Ensure the REMOTE_BAN chain exists and is wired into INPUT.
ensure_chain() {
  local ipt="$1"

  if ! $ipt -L "$CHAIN" -n &>/dev/null; then
    $ipt -N "$CHAIN"
    info "created $CHAIN chain ($ipt)"
  fi

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

  # Check if already banned — remove existing rule and timer before re-adding
  if $ipt -C "$CHAIN" -s "$ip" -j DROP &>/dev/null; then
    $ipt -D "$CHAIN" -s "$ip" -j DROP
    cancel_timer "$ip"
    info "updating existing ban for $ip"
  fi

  $ipt -A "$CHAIN" -s "$ip" -j DROP
  info "banned $ip ($ipt) for ${duration}s"

  # Schedule auto-unban via systemd transient timer
  local sanitized
  sanitized=$(sanitize_ip "$ip")
  local unit_name="remote-ban-expire-${sanitized}"

  # Clean up any stale units before creating
  systemctl reset-failed "${unit_name}.service" &>/dev/null || true
  systemctl reset-failed "${unit_name}.timer" &>/dev/null || true

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

  while $ipt -D "$CHAIN" -s "$ip" -j DROP &>/dev/null; do
    true
  done

  cancel_timer "$ip"
  info "unbanned $ip ($ipt)"
}

# Unban all IPs (flush ban rules, preserve trusted interface RETURN rules).
cmd_unban_all() {
  for ipt in iptables ip6tables; do
    ensure_chain "$ipt"
    $ipt -F "$CHAIN"
    setup_trusted_returns "$ipt"
    info "flushed all bans ($ipt)"
  done

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
    $ipt -L "$CHAIN" -n --line-numbers 2>/dev/null | \
      awk 'NR<=2 {next} /DROP/ {print $0}' || true
    echo ""
  done

  echo "=== Pending Expiry Timers ==="
  systemctl list-timers 'remote-ban-expire-*' --no-pager 2>/dev/null || echo "(none)"
}

# Cancel the expiry timer for a specific IP.
cancel_timer() {
  local ip="$1"
  local sanitized
  sanitized=$(sanitize_ip "$ip")
  local unit_name="remote-ban-expire-${sanitized}"

  systemctl stop "${unit_name}.timer" &>/dev/null || true
  systemctl stop "${unit_name}.service" &>/dev/null || true
  systemctl reset-failed "${unit_name}.timer" &>/dev/null || true
  systemctl reset-failed "${unit_name}.service" &>/dev/null || true
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
      systemctl reset-failed "$timer" &>/dev/null || true
      systemctl reset-failed "$service" &>/dev/null || true
    done <<< "$timers"
    info "cancelled all expiry timers"
  fi
}

# Entry point when called from SSH forced command.
# Strictly validates the command grammar to prevent abuse.
cmd_from_ssh() {
  local orig_cmd="${SSH_ORIGINAL_COMMAND:-}"
  [[ -n "$orig_cmd" ]] || die "no command provided (SSH_ORIGINAL_COMMAND is empty)"

  # Read into an array to avoid glob expansion
  local -a parts
  read -ra parts <<< "$orig_cmd"

  local subcmd="${parts[0]:-}"
  case "$subcmd" in
    ban)
      [[ ${#parts[@]} -eq 3 ]] || die "usage: ban <ip> <duration>"
      cmd_ban "${parts[1]}" "${parts[2]}"
      ;;
    unban)
      [[ ${#parts[@]} -eq 2 ]] || die "usage: unban <ip>"
      cmd_unban "${parts[1]}"
      ;;
    unban-all)
      [[ ${#parts[@]} -eq 1 ]] || die "usage: unban-all (no extra arguments)"
      cmd_unban_all
      ;;
    list)
      [[ ${#parts[@]} -eq 1 ]] || die "usage: list (no extra arguments)"
      cmd_list
      ;;
    *)
      die "unknown command from SSH: $subcmd"
      ;;
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
