import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../providers.js';
import resourceGroup from './resourceGroup.js';
import { allNodesWithName } from '../../lib/inventory.js';

export const device_analogrelay_net = new azure.network.Zone("device.analogrelay.net", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "device.analogrelay.net",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

const nodes = await allNodesWithName('devices');
// const records = nodes.map(node => {
//   new azure.network.RecordSet(`device.analogrelay.net/a/${node.name}`, {
//     zoneName: device_analogrelay_net.name,
//     resourceGroupName: resourceGroup.name,
//     recordType: "A",
//     ttl: 3600,
//     relativeRecordSetName: node.name,
//     aRecords: node.ipAddresses!.map(ipAddress => ({ ipv4Address: ipAddress })),
//   }, {
//     provider: analogcloud,
//   });
// });