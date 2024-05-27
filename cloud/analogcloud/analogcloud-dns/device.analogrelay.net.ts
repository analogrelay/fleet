import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../global.js';
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
