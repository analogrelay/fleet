import * as azure from "@pulumi/azure-native"
import resourceGroup from "./resourceGroup.js";
import { analogcloud } from "../../providers.js";

export const fastmailSpfValue: azure.types.input.network.TxtRecordArgs = {
  value: [ "v=spf1 include:spf.messagingengine.com ?all" ],
};

const fastmailMxRecords: azure.types.input.network.MxRecordArgs[] = [
  { exchange: "in1-smtp.messagingengine.com", preference: 10 },
  { exchange: "in2-smtp.messagingengine.com", preference: 20 },
];

function createDkimRecord(zoneName: string, index: number): azure.network.RecordSet {
  return new azure.network.RecordSet(`${zoneName}/cname/fm${index}._domainkey`, {
    zoneName: zoneName,
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

export function createDkimRecords(zoneName: string): azure.network.RecordSet[] {
  return [
    createDkimRecord(zoneName, 1),
    createDkimRecord(zoneName, 2),
    createDkimRecord(zoneName, 3),
  ]
}

export function createMailRecords(zoneName: string): azure.network.RecordSet[] {
  return [
    new azure.network.RecordSet(`${zoneName}/mx/root`, {
      zoneName: zoneName,
      resourceGroupName: resourceGroup.name,
      recordType: "MX",
      ttl: 3600,
      relativeRecordSetName: "@",
      mxRecords: fastmailMxRecords,
    }, {
      provider: analogcloud,
    }),
    ...createDkimRecords(zoneName),
  ]
}