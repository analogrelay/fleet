import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../global.js';
import resourceGroup from './resourceGroup.js';
import { createMailRecords, fastmailSpfValue } from './common.js';
import { loadInventory } from 'inventory';
import * as path from 'node:path';

export const analogrelay_net = new azure.network.Zone("analogrelay.net", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "analogrelay.net",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
  protect: true, // Protected because this zone is modified by external tools (Kubernetes external-dns)
});

createMailRecords("analogrelay.net", analogrelay_net);

new azure.network.RecordSet("analogrelay.net/txt/root", {
  zoneName: analogrelay_net.name,
  resourceGroupName: resourceGroup.name,
  recordType: "TXT",
  ttl: 3600,
  relativeRecordSetName: "@",
  txtRecords: [
    {
      value: [ "MS=ms25318237" ],
    },
    fastmailSpfValue,
    {
      value: [ "keybase-site-verification=THt3lJbmFrhKh-_kitGRvlNTwHBUOpvfyGYHdC6Bi8U" ],
    },
  ],
}, {
  provider: analogcloud,
  protect: true,
});

new azure.network.RecordSet("analogrelay.net/a/home", {
  zoneName: analogrelay_net.name,
  resourceGroupName: resourceGroup.name,
  recordType: "A",
  ttl: 3600,
  relativeRecordSetName: "home",
  aRecords: [
    {
      ipv4Address: "192.168.2.1"
    },
    {
      ipv4Address: "192.168.2.2"
    },
  ],
}, {
  provider: analogcloud,
});

// Create domains for networks
// CWD is the root of the pulumi project.
const inventory = await loadInventory(path.join(process.cwd(), "../inventory/inventory.toml"));

for (const network of inventory.networks.values()) {
  if (!network.dns) {
    continue;
  }

  const zone = new azure.network.Zone(`${network.subdomain}.analogrelay.net`, {
    location: "global",
    resourceGroupName: resourceGroup.name,
    zoneName: `${network.subdomain}.analogrelay.net`,
    zoneType: azure.network.ZoneType.Public,
  }, {
    provider: analogcloud,
  });

  new azure.network.RecordSet(`analogrelay.net/ns/${network.subdomain}`, {
    zoneName: analogrelay_net.name,
    resourceGroupName: resourceGroup.name,
    recordType: "NS",
    ttl: 3600,
    relativeRecordSetName: network.subdomain,
    nsRecords: zone.nameServers.apply(nameServers => nameServers.map(nameServer => ({ nsdname: nameServer }))),
  }, {
    provider: analogcloud,
  });

  for (const connection of network.connections) {
    new azure.network.RecordSet(`${network.subdomain}.analogrelay.net/a/${connection.hostname}`, {
      zoneName: zone.name,
      resourceGroupName: resourceGroup.name,
      recordType: "A",
      ttl: 3600,
      relativeRecordSetName: connection.hostname,
      aRecords: connection.ipv4Addresses.map(ipAddress => ({ ipv4Address: ipAddress })),
    }, {
      provider: analogcloud,
    });
  }
}
