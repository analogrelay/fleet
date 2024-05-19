import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../providers.js';
import resourceGroup from './resourceGroup.js';
import { createMailRecords, fastmailSpfValue } from './common.js';

export const analogrelay_dev = new azure.network.Zone("analogrelay.dev", {
  location: "global",
  resourceGroupName: resourceGroup.name,
  zoneName: "analogrelay.dev",
  zoneType: azure.network.ZoneType.Public,
}, {
  provider: analogcloud,
});

createMailRecords("analogrelay.dev");

new azure.network.RecordSet("analogrelay.dev/txt/root", {
  zoneName: analogrelay_dev.name,
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

new azure.network.RecordSet("analogrelay.dev/txt/_github-challenge-analogrelay", {
  zoneName: analogrelay_dev.name,
  resourceGroupName: resourceGroup.name,
  recordType: "TXT",
  ttl: 3600,
  relativeRecordSetName: "_github-challenge-analogrelay",
  txtRecords: [
    {
      value: [ "8479613193" ],
    },
  ]
}, {
  provider: analogcloud,
});

new azure.network.RecordSet("analogrelay.dev/cname/www", {
  zoneName: analogrelay_dev.name,
  resourceGroupName: resourceGroup.name,
  recordType: "CNAME",
  ttl: 3600,
  relativeRecordSetName: "www",
  cnameRecord: {
    cname: "analogrelay.github.io.",
  },
}, {
  provider: analogcloud,
});
