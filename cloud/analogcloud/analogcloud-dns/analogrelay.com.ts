import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../providers.js';
import resourceGroup from './resourceGroup.js';
import { createMailRecords, fastmailSpfValue } from './common.js';

export const analogrelay_com = new azure.network.Zone("analogrelay.com", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "analogrelay.com",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

createMailRecords("analogrelay.com");

new azure.network.RecordSet("analogrelay.com/txt/root", {
  zoneName: analogrelay_com.name,
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

new azure.network.RecordSet("analogrelay.com/txt/_atproto", {
  zoneName: analogrelay_com.name,
  resourceGroupName: resourceGroup.name,
  recordType: "TXT",
  ttl: 3600,
  relativeRecordSetName: "_atproto",
  txtRecords: [
    {
      value: [ "did=did:plc:2jim2f6p5xwgmy5orwvrl3u6" ],
    },
  ]
}, {
  provider: analogcloud,
});