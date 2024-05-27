import * as pulumi from '@pulumi/pulumi';
import * as azure from '@pulumi/azure-native';
import * as random from '@pulumi/random';

import resourceGroup from './resourceGroup.js';
import { primaryNodeNsg, privateDns, subnets } from './network.js';
import { msftbenefit } from '../../global.js';
import { ashleyCanWrite, vault } from './vault.js';
import { adminSshKey, k3sServerIdentity } from './identity.js';
import { readFile } from 'fs/promises';

export const publicIp = new azure.network.PublicIPAddress("analogcompute/p01/ip", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  publicIpAddressName: "analogcompute-p01-ip",
  publicIPAllocationMethod: azure.network.IPAllocationMethod.Static,
  dnsSettings: {
      domainNameLabel: 'analogcompute-p01',
  },
}, { provider: msftbenefit });

export const nic = new azure.network.NetworkInterface("analogcompute/p01/nic", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  networkInterfaceName: "analogcompute-p01-nic",
  networkSecurityGroup: {
    id: primaryNodeNsg.id,
  },
  ipConfigurations: [{
    name: 'analogcompute-p01-ipcfg-01',
    privateIPAddress: "10.0.1.10", // Static assigned private IP.
    privateIPAllocationMethod: 'Static',
    subnet: {
      id: subnets["k3s-primary"].id?.apply(id => id!),
    },
    publicIPAddress: {
      id: publicIp.id,
    },
  }],
}, { provider: msftbenefit });

const k3sToken = new random.RandomPassword("k3sToken", {
  length: 32,
  special: false,
  keepers: {
    version: "v1", // Change this to force a new token to be generated but be aware that cluster nodes will need to be updated.
  }
});

export const k3sTokenSecret = new azure.keyvault.Secret("analogcompute/vault/k3sToken", {
  resourceGroupName: resourceGroup.name,
  vaultName: vault.name,
  secretName: "k3s-token",
  properties: {
    value: k3sToken.result,
  },
}, { 
  provider: msftbenefit,
  dependsOn: [ashleyCanWrite]
});

// Read the cloud init file, and replace the placeholder with the identity ID.
const cloudInitTemplate = await readFile('./msftbenefit/analogcompute/k3s-primary.cloud-init.sh', { encoding: 'utf-8' });

const cloudInit = pulumi.all([k3sServerIdentity.id, publicIp.ipAddress, publicIp.dnsSettings]).apply(([id, ip, dns]) => {
  return cloudInitTemplate.replace(/@IDENTITY_ID@/g, id)
    .replace(/@PUBLIC_IP@/g, ip!)
    .replace(/@AZURE_DNS_NAME@/g, dns!.fqdn!);
});

export const vmPrimary = new azure.compute.VirtualMachine("analogcompute/p01/vm", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  vmName: "analogcompute-p01",
  hardwareProfile: {
    vmSize: azure.compute.VirtualMachineSizeTypes.Standard_B2s,
  },
  storageProfile: {
    osDisk: {
      createOption: azure.compute.DiskCreateOption.FromImage,
      managedDisk: {
        storageAccountType: azure.compute.StorageAccountTypes.StandardSSD_LRS,
      },
      deleteOption: azure.compute.DiskDeleteOptionTypes.Delete,
    },
    imageReference: {
      publisher: "Canonical",
      offer: "0001-com-ubuntu-server-jammy",
      sku: "22_04-lts-gen2",
      version: "latest",
    },
  },
  networkProfile: {
    networkInterfaces: [{
      id: nic.id,
    }],
  },
  osProfile: {
    computerName: "analogcompute-p01",
    adminUsername: "azureuser",
    linuxConfiguration: {
      disablePasswordAuthentication: true,
      patchSettings: {
        patchMode: azure.compute.LinuxVMGuestPatchMode.AutomaticByPlatform,
        automaticByPlatformSettings: {
          rebootSetting: azure.compute.LinuxVMGuestPatchAutomaticByPlatformRebootSetting.IfRequired,
        },
      },
      ssh: {
        publicKeys: [{
          keyData: adminSshKey.publicKey.apply(key => key!),
          path: `/home/azureuser/.ssh/authorized_keys`,
        }],
      }
    },
  },
  securityProfile: {
    securityType: azure.compute.SecurityTypes.TrustedLaunch,
    uefiSettings: {
      secureBootEnabled: true,
      vTpmEnabled: true,
    },
  },
  identity: {
    type: azure.compute.ResourceIdentityType.SystemAssigned_UserAssigned,
    userAssignedIdentities: [
      k3sServerIdentity.id,
    ],
  },
  userData: cloudInit.apply(cloudInit => Buffer.from(cloudInit).toString('base64')),
}, { provider: msftbenefit });

new azure.network.PrivateRecordSet("analogcompute/vnet/private-dns/a/root", {
  privateZoneName: privateDns.name,
  resourceGroupName: resourceGroup.name,
  recordType: "A",
  ttl: 3600,
  relativeRecordSetName: "@",
  aRecords: [
    {
      ipv4Address: nic.ipConfigurations.apply(config => config![0].privateIPAddress!),
    }
  ]
});