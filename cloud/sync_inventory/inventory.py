from dataclasses import dataclass
from pathlib import Path

import yaml

from . import azure_vm


@dataclass
class Node:
    name: str
    realm: str
    ip_address: str
    mac_address: str | None


@dataclass
class Service:
    name: str
    ip_address: str | None = None
    canonical_name: str | None = None


@dataclass
class AzureDnsConfig:
    subscription: str
    resource_group: str


@dataclass
class Zone:
    name: str
    nodes: list[Node]
    services: list[Service]
    partial: bool = False
    azure_dns: AzureDnsConfig | None = None


@dataclass
class Inventory:
    zones: list[Zone]

    def all_nodes(self) -> list[tuple["Zone", Node]]:
        return [(zone, node) for zone in self.zones for node in zone.nodes]


def load(path: Path) -> Inventory:
    with open(path) as f:
        data = yaml.safe_load(f)

    zones = []
    for zone_name, zone_data in data.get("zones", {}).items():
        nodes = []
        for n in zone_data.get("nodes", []):
            mac = n.get("macAddress")
            if "azureVm" in n:
                vm = n["azureVm"]
                ip_address = azure_vm.get_public_ip(vm["resourceGroup"], vm["name"])
            else:
                ip_address = n["ipAddress"]
            nodes.append(
                Node(
                    name=n["name"],
                    realm=n["realm"],
                    ip_address=ip_address,
                    mac_address=mac.upper() if mac else None,
                )
            )

        services = []
        for s in zone_data.get("services", []):
            ip_address = s.get("ipAddress")
            canonical_name = s.get("canonicalName")
            if ip_address and canonical_name:
                raise ValueError(
                    f"Service {s['name']!r} in zone {zone_name!r} specifies both "
                    f"ipAddress and canonicalName; only one is permitted"
                )
            if not ip_address and not canonical_name:
                raise ValueError(
                    f"Service {s['name']!r} in zone {zone_name!r} must specify "
                    f"either ipAddress or canonicalName"
                )
            services.append(
                Service(
                    name=s["name"],
                    ip_address=ip_address,
                    canonical_name=canonical_name,
                )
            )

        partial = zone_data.get("partial", False)
        azure_dns_config = None
        if "azureDns" in zone_data:
            az = zone_data["azureDns"]
            azure_dns_config = AzureDnsConfig(
                subscription=az["subscription"],
                resource_group=az["resourceGroup"],
            )
        zones.append(
            Zone(
                name=zone_name,
                nodes=nodes,
                services=services,
                partial=partial,
                azure_dns=azure_dns_config,
            )
        )

    return Inventory(zones=zones)
