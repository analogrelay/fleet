import * as azure from "@pulumi/azure-native"
import resourceGroup from "./resourceGroup.js";
import { analogcloud } from "../../global.js";

export const fastmailSpfValue: azure.types.input.network.TxtRecordArgs = {
  value: [ "v=spf1 include:spf.messagingengine.com ?all" ],
};

const fastmailMxRecords: azure.types.input.network.MxRecordArgs[] = [
  { exchange: "in1-smtp.messagingengine.com", preference: 10 },
  { exchange: "in2-smtp.messagingengine.com", preference: 20 },
];

function createDkimRecord(zoneName: string, zone: azure.network.Zone, index: number): azure.network.RecordSet {
  return new azure.network.RecordSet(`${zoneName}/cname/fm${index}._domainkey`, {
    zoneName: zone.name,
    resourceGroupName: resourceGroup.name,
    recordType: "CNAME",
    ttl: 3600,
    relativeRecordSetName: `fm${index}._domainkey`,
    cnameRecord: {
      cname: `fm${index}.${zoneName}.dkim.fmhosted.com.`,
    },
  }, {
    provider: analogcloud,
  });
}

export function createDkimRecords(zoneName: string, zone: azure.network.Zone): azure.network.RecordSet[] {
  return [
    createDkimRecord(zoneName, zone, 1),
    createDkimRecord(zoneName, zone, 2),
    createDkimRecord(zoneName, zone, 3),
  ]
}

export function createMailRecords(zoneName: string, zone: azure.network.Zone): azure.network.RecordSet[] {
  return [
    new azure.network.RecordSet(`${zoneName}/mx/root`, {
      zoneName: zone.name,
      resourceGroupName: resourceGroup.name,
      recordType: "MX",
      ttl: 3600,
      relativeRecordSetName: "@",
      mxRecords: fastmailMxRecords,
    }, {
      provider: analogcloud,
    }),
    ...createDkimRecords(zoneName, zone),
  ]
}