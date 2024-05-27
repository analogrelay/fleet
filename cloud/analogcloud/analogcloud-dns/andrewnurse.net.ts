import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../global.js';
import resourceGroup from './resourceGroup.js';
import { createMailRecords, fastmailSpfValue } from './common.js';

export const andrewnurse_net = new azure.network.Zone("andrewnurse.net", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "andrewnurse.net",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

createMailRecords("andrewnurse.net", andrewnurse_net);

new azure.network.RecordSet("andrewnurse.net/txt/root", {
  zoneName: andrewnurse_net.name,
  resourceGroupName: resourceGroup.name,
  recordType: "TXT",
  ttl: 3600,
  relativeRecordSetName: "@",
  txtRecords: [
    fastmailSpfValue,
  ],
}, {
  provider: analogcloud,
});