import json
import os
import subprocess

SUBSCRIPTION_ID = os.environ.get(
    "AZURE_SUBSCRIPTION_ID", "466cf680-808d-4446-94b3-f367eaa60ba1"
)


def get_public_ip(resource_group: str, name: str) -> str:
    """Return the first public IP address attached to an Azure VM."""
    cmd = [
        "az",
        "vm",
        "list-ip-addresses",
        "--resource-group",
        resource_group,
        "--name",
        name,
        "--subscription",
        SUBSCRIPTION_ID,
        "-o",
        "json",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"Failed to get IP for VM {name!r} in {resource_group!r}: "
            f"{result.stderr.strip()}"
        )
    data = json.loads(result.stdout)
    try:
        ip = data[0]["virtualMachine"]["network"]["publicIpAddresses"][0]["ipAddress"]
    except (IndexError, KeyError) as e:
        raise RuntimeError(
            f"No public IP found for VM {name!r} in {resource_group!r}"
        ) from e
    return ip
