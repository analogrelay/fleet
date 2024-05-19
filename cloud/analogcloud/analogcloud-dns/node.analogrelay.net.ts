import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../providers.js';
import resourceGroup from './resourceGroup.js';
import { allNodesWithName } from '../../lib/inventory.js';

export const node_analogrelay_net = new azure.network.Zone("node.analogrelay.net", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "node.analogrelay.net",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

const nodes = await allNodesWithName('node');
const records = nodes.map(node => {
  new azure.network.RecordSet(`node.analogrelay.net/a/${node.name}`, {
    zoneName: node_analogrelay_net.name,
    resourceGroupName: resourceGroup.name,
    recordType: "A",
    ttl: 3600,
    relativeRecordSetName: node.name,
    aRecords: node.ipAddresses!.map(ipAddress => ({ ipv4Address: ipAddress })),
  }, {
    provider: analogcloud,
  });
});