import json
import subprocess
from dataclasses import dataclass

from rich.console import Console

from .inventory import Zone

TTL = 300


@dataclass
class DnsAction:
    kind: str  # CREATE, UPDATE, DELETE
    record_type: str  # A, CNAME
    name: str
    zone: str
    old_value: str | None
    new_value: str | None


def _az(subscription: str, *args: str) -> dict | list:
    cmd = ["az", *args, "-o", "json", "--subscription", subscription]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"az command failed: {result.stderr.strip()}")
    return json.loads(result.stdout) if result.stdout.strip() else {}


def _az_no_output(subscription: str, *args: str) -> None:
    cmd = ["az", *args, "--subscription", subscription]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"az command failed: {result.stderr.strip()}")


def verify_subscription(subscription: str) -> None:
    result = subprocess.run(
        [
            "az",
            "account",
            "show",
            "--subscription",
            subscription,
            "--query",
            "id",
            "-o",
            "tsv",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Cannot access subscription {subscription!r}. "
            "Is az CLI logged in and does this subscription exist?"
        )


def compute_plan(zone: Zone) -> tuple[list[DnsAction], bool]:
    """Returns (actions, zone_is_new)."""
    assert zone.azure_dns is not None
    subscription = zone.azure_dns.subscription
    resource_group = zone.azure_dns.resource_group

    # Check if zone exists
    result = subprocess.run(
        [
            "az",
            "network",
            "dns",
            "zone",
            "show",
            "--name",
            zone.name,
            "--resource-group",
            resource_group,
            "--subscription",
            subscription,
            "-o",
            "json",
        ],
        capture_output=True,
        text=True,
    )
    zone_is_new = result.returncode != 0

    if zone_is_new:
        current_a_records: dict[str, str] = {}
        current_cname_records: dict[str, str] = {}
    else:
        # Fetch A records
        a_records = _az(
            subscription,
            "network",
            "dns",
            "record-set",
            "a",
            "list",
            "--zone-name",
            zone.name,
            "--resource-group",
            resource_group,
        )
        current_a_records = {}
        for r in a_records:
            rname = r["name"]
            ips = [a["ipv4Address"] for a in r.get("aRecords", [])]
            if ips:
                current_a_records[rname] = ips[0]

        # Fetch CNAME records
        cname_records = _az(
            subscription,
            "network",
            "dns",
            "record-set",
            "cname",
            "list",
            "--zone-name",
            zone.name,
            "--resource-group",
            resource_group,
        )
        current_cname_records = {}
        for r in cname_records:
            rname = r["name"]
            cname_rec = r.get("cnameRecord")
            if cname_rec:
                current_cname_records[rname] = cname_rec["cname"]

    # Build desired state from nodes (all A records) and services (A or CNAME)
    desired_a: dict[str, str] = {n.name: n.ip_address for n in zone.nodes}
    desired_cname: dict[str, str] = {}

    for svc in zone.services:
        if svc.ip_address:
            desired_a[svc.name] = svc.ip_address
        elif svc.canonical_name:
            desired_cname[svc.name] = svc.canonical_name

    actions: list[DnsAction] = []

    # Plan A records
    for name, ip in desired_a.items():
        if name not in current_a_records:
            actions.append(DnsAction("CREATE", "A", name, zone.name, None, ip))
        elif current_a_records[name] != ip:
            actions.append(
                DnsAction("UPDATE", "A", name, zone.name, current_a_records[name], ip)
            )

    # Plan CNAME records
    for name, cname in desired_cname.items():
        if name not in current_cname_records:
            actions.append(DnsAction("CREATE", "CNAME", name, zone.name, None, cname))
        elif current_cname_records[name] != cname:
            actions.append(
                DnsAction(
                    "UPDATE",
                    "CNAME",
                    name,
                    zone.name,
                    current_cname_records[name],
                    cname,
                )
            )

    if not zone.partial:
        for name, ip in current_a_records.items():
            if name not in desired_a:
                actions.append(DnsAction("DELETE", "A", name, zone.name, ip, None))
        for name, cname in current_cname_records.items():
            if name not in desired_cname:
                actions.append(
                    DnsAction("DELETE", "CNAME", name, zone.name, cname, None)
                )

    return actions, zone_is_new


def print_plan(
    zone: Zone, actions: list[DnsAction], zone_is_new: bool, console: Console
) -> None:
    suffix = ""
    if zone_is_new:
        suffix = " [yellow][NEW - will create][/yellow]"
    elif zone.partial:
        suffix = " [dim][partial][/dim]"
    resource_group = zone.azure_dns.resource_group if zone.azure_dns else "?"
    console.print(f"[bold]Zone:[/bold] {zone.name} ({resource_group}){suffix}")

    if not actions:
        console.print("  (no changes)")
        return

    for a in actions:
        if a.kind == "CREATE":
            console.print(
                f"  [green]\\[CREATE][/green] {a.record_type:<5}  {a.name:<20} {a.new_value}"
            )
        elif a.kind == "UPDATE":
            console.print(
                f"  [yellow]\\[UPDATE][/yellow] {a.record_type:<5}  {a.name:<20} {a.old_value} -> {a.new_value}"
            )
        elif a.kind == "DELETE":
            console.print(
                f"  [red]\\[DELETE][/red] {a.record_type:<5}  {a.name:<20} {a.old_value}"
            )


def apply_plan(
    zone: Zone, actions: list[DnsAction], zone_is_new: bool, console: Console
) -> int:
    assert zone.azure_dns is not None
    subscription = zone.azure_dns.subscription
    resource_group = zone.azure_dns.resource_group
    errors = 0

    if zone_is_new:
        console.print(f"  Creating zone {zone.name}...")
        try:
            zone_info = _az(
                subscription,
                "network",
                "dns",
                "zone",
                "create",
                "--name",
                zone.name,
                "--resource-group",
                resource_group,
            )
            ns_records = zone_info.get("nameServers", [])
            if ns_records:
                console.print(
                    f"  [yellow]WARNING: New zone created. Update your registrar with these nameservers:[/yellow]"
                )
                for ns in ns_records:
                    console.print(f"    {ns}")
        except RuntimeError as e:
            console.print(f"  [red]ERROR creating zone: {e}[/red]")
            errors += 1
            return errors

    for a in actions:
        try:
            if a.kind == "CREATE":
                if a.record_type == "A":
                    _az_no_output(
                        subscription,
                        "network",
                        "dns",
                        "record-set",
                        "a",
                        "add-record",
                        "--record-set-name",
                        a.name,
                        "--zone-name",
                        a.zone,
                        "--resource-group",
                        resource_group,
                        "--ipv4-address",
                        a.new_value,
                        "--ttl",
                        str(TTL),
                    )
                elif a.record_type == "CNAME":
                    _az_no_output(
                        subscription,
                        "network",
                        "dns",
                        "record-set",
                        "cname",
                        "set-record",
                        "--record-set-name",
                        a.name,
                        "--zone-name",
                        a.zone,
                        "--resource-group",
                        resource_group,
                        "--cname",
                        a.new_value,
                        "--ttl",
                        str(TTL),
                    )
                console.print(
                    f"  [green]Created[/green] {a.record_type} {a.name} -> {a.new_value}"
                )
            elif a.kind == "UPDATE":
                if a.record_type == "A":
                    _az_no_output(
                        subscription,
                        "network",
                        "dns",
                        "record-set",
                        "a",
                        "delete",
                        "--name",
                        a.name,
                        "--zone-name",
                        a.zone,
                        "--resource-group",
                        resource_group,
                        "--yes",
                    )
                    _az_no_output(
                        subscription,
                        "network",
                        "dns",
                        "record-set",
                        "a",
                        "add-record",
                        "--record-set-name",
                        a.name,
                        "--zone-name",
                        a.zone,
                        "--resource-group",
                        resource_group,
                        "--ipv4-address",
                        a.new_value,
                        "--ttl",
                        str(TTL),
                    )
                elif a.record_type == "CNAME":
                    _az_no_output(
                        subscription,
                        "network",
                        "dns",
                        "record-set",
                        "cname",
                        "set-record",
                        "--record-set-name",
                        a.name,
                        "--zone-name",
                        a.zone,
                        "--resource-group",
                        resource_group,
                        "--cname",
                        a.new_value,
                        "--ttl",
                        str(TTL),
                    )
                console.print(
                    f"  [yellow]Updated[/yellow] {a.record_type} {a.name} -> {a.new_value}"
                )
            elif a.kind == "DELETE":
                _az_no_output(
                    subscription,
                    "network",
                    "dns",
                    "record-set",
                    a.record_type.lower(),
                    "delete",
                    "--name",
                    a.name,
                    "--zone-name",
                    a.zone,
                    "--resource-group",
                    resource_group,
                    "--yes",
                )
                console.print(f"  [red]Deleted[/red] {a.record_type} {a.name}")
        except RuntimeError as e:
            console.print(f"  [red]ERROR applying {a.kind} for {a.name}: {e}[/red]")
            errors += 1

    return errors
