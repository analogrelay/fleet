import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../providers.js';
import resourceGroup from './resourceGroup.js';
import { createMailRecords, fastmailSpfValue } from './common.js';

export const analogrelay_ca = new azure.network.Zone("analogrelay.ca", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "analogrelay.ca",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

createMailRecords("analogrelay.ca");

new azure.network.RecordSet("analogrelay.ca/txt/root", {
  zoneName: analogrelay_ca.name,
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