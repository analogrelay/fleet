import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../global.js';
import resourceGroup from './resourceGroup.js';
import { createMailRecords, fastmailSpfValue } from './common.js';
import { publicIp } from '../../msftbenefit/analogcompute/primary.js';

export const analogrelay_cloud = new azure.network.Zone("analogrelay.cloud", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "analogrelay.cloud",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

createMailRecords("analogrelay.cloud", analogrelay_cloud);

new azure.network.RecordSet("analogrelay.cloud/txt/root", {
  zoneName: analogrelay_cloud.name,
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

new azure.network.RecordSet("analogrelay.cloud/a/root", {
  zoneName: analogrelay_cloud.name,
  resourceGroupName: resourceGroup.name,
  recordType: "A",
  ttl: 3600,
  relativeRecordSetName: "@",
  aRecords: [
    {
      ipv4Address: publicIp.ipAddress.apply(ip => ip!),
    }
  ],
}, { provider: analogcloud });