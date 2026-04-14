import argparse
import sys
from pathlib import Path

from rich.console import Console

from . import azure_dns, inventory, mikrotik


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync inventory to Azure DNS and MikroTik DHCP")
    parser.add_argument("-n", "--dry-run", action="store_true",
                        help="Show plan only, make no changes")
    parser.add_argument("--azure-only", action="store_true", help="Only sync Azure DNS")
    parser.add_argument("--router-only", action="store_true", help="Only sync MikroTik DHCP")
    parser.add_argument("--inventory", default="inventory.yaml", metavar="PATH",
                        help="Path to inventory file (default: inventory.yaml)")
    args = parser.parse_args()

    console = Console()
    inv = inventory.load(Path(args.inventory))

    do_azure = not args.router_only
    do_mikrotik = not args.azure_only

    has_plan = False
    errors = 0

    # --- Azure DNS ---
    dns_plans: list[tuple] = []
    if do_azure:
        console.print("\n[bold]=== Azure DNS ===[/bold]")
        dns_zones = [z for z in inv.zones if z.azure_dns is not None]
        subscriptions = {z.azure_dns.subscription for z in dns_zones}
        for subscription in subscriptions:
            try:
                azure_dns.verify_subscription(subscription)
            except RuntimeError as e:
                console.print(f"[red]ERROR: {e}[/red]")
                return 1

        for zone in dns_zones:
            try:
                actions, zone_is_new = azure_dns.compute_plan(zone)
                dns_plans.append((zone, actions, zone_is_new))
                azure_dns.print_plan(zone, actions, zone_is_new, console)
                if actions:
                    has_plan = True
            except RuntimeError as e:
                console.print(f"[red]ERROR computing plan for zone {zone.name}: {e}[/red]")
                return 1

    # --- MikroTik DHCP ---
    dhcp_actions: list = []
    if do_mikrotik:
        console.print(f"\n[bold]=== MikroTik DHCP ({inv.router}) ===[/bold]")
        try:
            dhcp_actions = mikrotik.compute_plan(inv)
            mikrotik.print_plan(dhcp_actions, console)
            if any(a.kind not in ("WARN", "INFO") for a in dhcp_actions):
                has_plan = True
        except RuntimeError as e:
            console.print(f"[red]ERROR: {e}[/red]")
            return 1

    console.print()

    if args.dry_run:
        return 0

    if not has_plan:
        console.print("[green]Nothing to do.[/green]")
        return 0

    try:
        answer = input("Apply these changes? [y/N] ").strip().lower()
    except (KeyboardInterrupt, EOFError):
        console.print("\nAborted.")
        return 1

    if answer != "y":
        console.print("Aborted.")
        return 0

    # Apply Azure DNS
    if do_azure:
        console.print("\n[bold]Applying Azure DNS changes...[/bold]")
        for zone, actions, zone_is_new in dns_plans:
            if not actions and not zone_is_new:
                continue
            console.print(f"Zone: {zone.name}")
            errors += azure_dns.apply_plan(zone, actions, zone_is_new, console)

    # Apply MikroTik
    if do_mikrotik:
        console.print("\n[bold]Applying MikroTik DHCP changes...[/bold]")
        errors += mikrotik.apply_plan(dhcp_actions, inv.router, console)

    if errors:
        console.print(f"\n[red]{errors} error(s) occurred.[/red]")
        return 1

    console.print("\n[green]Done.[/green]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
