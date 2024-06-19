import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../global.js';
import resourceGroup from './resourceGroup.js';
import { node_analogrelay_net } from './node.analogrelay.net.js';
import { device_analogrelay_net } from './device.analogrelay.net.js';
import { createMailRecords, fastmailSpfValue } from './common.js';

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

new azure.network.RecordSet("analogrelay.net/ns/node", {
  zoneName: analogrelay_net.name,
  resourceGroupName: resourceGroup.name,
  recordType: "NS",
  ttl: 3600,
  relativeRecordSetName: "node",
  nsRecords: node_analogrelay_net.nameServers.apply(nameServers => nameServers.map(nameServer => ({ nsdname: nameServer }))),
}, {
  provider: analogcloud,
});

new azure.network.RecordSet("analogrelay.net/ns/device", {
  zoneName: analogrelay_net.name,
  resourceGroupName: resourceGroup.name,
  recordType: "NS",
  ttl: 3600,
  relativeRecordSetName: "device",
  nsRecords: device_analogrelay_net.nameServers.apply(nameServers => nameServers.map(nameServer => ({ nsdname: nameServer }))),
}, {
  provider: analogcloud,
});
