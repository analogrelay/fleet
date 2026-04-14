import os
import re
from dataclasses import dataclass
import paramiko
from rich.console import Console

from .inventory import Inventory

MIKROTIK_USER = os.environ.get("MIKROTIK_USER", "")
MIKROTIK_PORT = int(os.environ.get("MIKROTIK_PORT", "22"))
MIKROTIK_DHCP_SERVER = os.environ.get("MIKROTIK_DHCP_SERVER", "primary/dhcp")

@dataclass
class Lease:
    mac: str
    ip: str
    comment: str
    # raw index from RouterOS (used for removal)
    index: str | None = None


@dataclass
class DhcpAction:
    kind: str  # CREATE, UPDATE, DELETE, ADOPT_DELETE, WARN, INFO
    inv_name: str
    mac: str
    old_ip: str | None
    new_ip: str | None
    message: str | None = None  # for WARN


def _run(client: paramiko.SSHClient, cmd: str) -> str:
    _, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode()
    err = stderr.read().decode()
    if err.strip():
        raise RuntimeError(f"RouterOS error: {err.strip()}")
    return out


def _find_agent_sock() -> str:
    """Find the 1Password SSH agent socket. Currently only supports macOS."""
    import sys
    if sys.platform != "darwin":
        raise RuntimeError(
            "MikroTik SSH auth requires the 1Password SSH agent, which is only "
            "supported on macOS in this script. Contributions welcome."
        )
    sock = os.path.expanduser(
        "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    )
    if not os.path.exists(sock):
        raise RuntimeError(
            f"1Password SSH agent socket not found at {sock}. "
            "Is 1Password running with the SSH agent enabled?"
        )
    return sock


def _connect(host: str) -> paramiko.SSHClient:
    if not host:
        raise RuntimeError("Router address is required (set 'router' in inventory.yaml)")
    if not MIKROTIK_USER:
        raise RuntimeError("MIKROTIK_USER environment variable is required")

    sock = _find_agent_sock()
    old = os.environ.get("SSH_AUTH_SOCK")
    os.environ["SSH_AUTH_SOCK"] = sock
    try:
        # Keep the Agent object alive through the connect call — AgentKey objects
        # hold a reference to it for signing, so it must not be GC'd yet.
        agent = paramiko.Agent()
        agent_keys = agent.get_keys()
    finally:
        if old is None:
            os.environ.pop("SSH_AUTH_SOCK", None)
        else:
            os.environ["SSH_AUTH_SOCK"] = old

    if not agent_keys:
        raise RuntimeError(
            "No keys found in the 1Password SSH agent. "
            "Make sure your key is added and 1Password is unlocked."
        )

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    last_exc: Exception | None = None
    for key in agent_keys:
        try:
            client.connect(
                host,
                port=MIKROTIK_PORT,
                username=MIKROTIK_USER,
                pkey=key,
                allow_agent=False,
                look_for_keys=False,
            )
            return client
        except paramiko.AuthenticationException as e:
            last_exc = e
            continue

    raise RuntimeError(
        f"SSH authentication to {host} failed with all "
        f"{len(agent_keys)} agent key(s): {last_exc}"
    )


def _parse_leases(output: str) -> list[dict]:
    """Parse RouterOS terse output into list of dicts."""
    leases = []
    for line in output.splitlines():
        line = line.strip()
        if not line:
            continue
        entry: dict = {}
        # Extract index at start (e.g. "0 " or " 1 ")
        m = re.match(r'^\s*(\d+)\s+(.*)', line)
        if m:
            entry["index"] = m.group(1)
            line = m.group(2)
        # Parse key=value pairs (values may be quoted)
        for kv in re.finditer(r'(\S+)=("(?:[^"\\]|\\.)*"|\S+)', line):
            key = kv.group(1)
            val = kv.group(2).strip('"')
            entry[key] = val
        leases.append(entry)
    return leases


def _get_current_leases(client: paramiko.SSHClient) -> tuple[dict[str, Lease], dict[str, Lease]]:
    """
    Returns (managed, unmanaged) where:
    - managed: {inv_name -> Lease} for leases with comment starting 'inv:'
    - unmanaged: {mac -> Lease} for static leases without inv: prefix
    """
    out = _run(client, "/ip dhcp-server lease print terse where type=static")
    parsed = _parse_leases(out)

    managed: dict[str, Lease] = {}
    unmanaged: dict[str, Lease] = {}

    for entry in parsed:
        mac = entry.get("mac-address", "").upper()
        ip = entry.get("address", "")
        comment = entry.get("comment", "")
        index = entry.get("index")
        lease = Lease(mac=mac, ip=ip, comment=comment, index=index)

        if comment.startswith("inv:"):
            inv_name = comment[4:]
            managed[inv_name] = lease
        else:
            unmanaged[mac] = lease

    return managed, unmanaged


def compute_plan(inventory: Inventory) -> list[DhcpAction]:
    client = _connect(inventory.router)
    try:
        managed, unmanaged = _get_current_leases(client)
    finally:
        client.close()

    actions: list[DhcpAction] = []
    desired_names: set[str] = set()

    for _, node in inventory.all_nodes():
        if node.mac_address is None:
            continue
        desired_names.add(node.name)
        current = managed.get(node.name)

        if current is None:
            action = DhcpAction("CREATE", node.name, node.mac_address, None, node.ip_address)
            actions.append(action)
            # Conflict check: unmanaged lease with same MAC
            if node.mac_address in unmanaged:
                conflict = unmanaged[node.mac_address]
                if conflict.ip == node.ip_address:
                    # Same IP+MAC — adopt: delete the old unmanaged lease first,
                    # then let the CREATE below bring it under management.
                    actions.insert(len(actions) - 1, DhcpAction(
                        "ADOPT_DELETE", node.name, node.mac_address, conflict.ip, None,
                        message=conflict.comment,
                    ))
                    actions.append(DhcpAction(
                        "INFO", node.name, node.mac_address, None, None,
                        message=f"MAC {node.mac_address} already has unmanaged lease {conflict.comment!r} with matching IP — adopting",
                    ))
                else:
                    actions.append(DhcpAction(
                        "WARN", node.name, node.mac_address, None, None,
                        message=f"MAC {node.mac_address} already has unmanaged lease {conflict.comment!r} with different IP {conflict.ip!r} - will conflict",
                    ))
        elif current.ip != node.ip_address:
            actions.append(DhcpAction("UPDATE", node.name, node.mac_address, current.ip, node.ip_address))

    for inv_name in managed:
        if inv_name not in desired_names:
            lease = managed[inv_name]
            actions.append(DhcpAction("DELETE", inv_name, lease.mac, lease.ip, None))

    return actions


def print_plan(actions: list[DhcpAction], console: Console) -> None:
    if not actions:
        console.print("  (no changes)")
        return

    for a in actions:
        if a.kind == "CREATE":
            console.print(f"  [green]\\[CREATE][/green] DHCP  inv:{a.inv_name:<20} {a.mac}  {a.new_ip}")
        elif a.kind == "UPDATE":
            console.print(f"  [yellow]\\[UPDATE][/yellow] DHCP  inv:{a.inv_name:<20} {a.mac}  {a.old_ip} -> {a.new_ip}")
        elif a.kind == "DELETE":
            console.print(f"  [red]\\[DELETE][/red] DHCP  inv:{a.inv_name:<20} {a.mac}  {a.old_ip}")
        elif a.kind == "ADOPT_DELETE":
            console.print(f"  [red]\\[DELETE][/red] DHCP  {a.message:<24} {a.mac}  {a.old_ip} (unmanaged, replacing with inv:{a.inv_name})")
        elif a.kind == "WARN":
            console.print(f"  [yellow]\\[WARN][/yellow]   DHCP  {a.message}")
        elif a.kind == "INFO":
            console.print(f"  [cyan]\\[INFO][/cyan]   DHCP  {a.message}")


def apply_plan(actions: list[DhcpAction], host: str, console: Console) -> int:
    actionable = [a for a in actions if a.kind not in ("WARN", "INFO")]
    if not actionable:
        return 0

    client = _connect(host)
    errors = 0
    try:
        for a in actionable:
            try:
                if a.kind == "ADOPT_DELETE":
                    _run(client, f"/ip dhcp-server lease remove [find mac-address={a.mac} address={a.old_ip} type=static]")
                    console.print(f"  [red]Deleted[/red] unmanaged lease {a.message!r} ({a.mac} {a.old_ip})")
                elif a.kind == "CREATE":
                    _run(client, (
                        f"/ip dhcp-server lease add"
                        f" address={a.new_ip}"
                        f" mac-address={a.mac}"
                        f" comment=inv:{a.inv_name}"
                        f" server={MIKROTIK_DHCP_SERVER}"
                    ))
                    console.print(f"  [green]Created[/green] inv:{a.inv_name} {a.mac} -> {a.new_ip}")
                elif a.kind == "UPDATE":
                    _run(client, f'/ip dhcp-server lease remove [find comment="inv:{a.inv_name}"]')
                    _run(client, (
                        f"/ip dhcp-server lease add"
                        f" address={a.new_ip}"
                        f" mac-address={a.mac}"
                        f" comment=inv:{a.inv_name}"
                        f" server={MIKROTIK_DHCP_SERVER}"
                    ))
                    console.print(f"  [yellow]Updated[/yellow] inv:{a.inv_name} -> {a.new_ip}")
                elif a.kind == "DELETE":
                    _run(client, f'/ip dhcp-server lease remove [find comment="inv:{a.inv_name}"]')
                    console.print(f"  [red]Deleted[/red] inv:{a.inv_name}")
            except RuntimeError as e:
                console.print(f"  [red]ERROR applying {a.kind} for inv:{a.inv_name}: {e}[/red]")
                errors += 1
    finally:
        client.close()

    return errors
