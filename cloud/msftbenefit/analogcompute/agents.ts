import * as azure from '@pulumi/azure-native';
import * as pulumi from '@pulumi/pulumi';

import resourceGroup from './resourceGroup.js';
import { agentNodeNsg, subnets } from './network.js';
import { adminSshKey, k3sAgentIdentity } from './identity.js';

import { readFile } from 'fs/promises';

const agentCount = 0;

// Read the cloud init file, and replace the placeholder with the identity ID.
const cloudInitTemplate = await readFile('./msftbenefit/analogcompute/k3s-agent.cloud-init.sh', { encoding: 'utf-8' });

const cloudInit = pulumi.all([k3sAgentIdentity.id]).apply(([id]) => {
  return cloudInitTemplate.replace(/@IDENTITY_ID@/g, id)
});

export const agentScaleSet = new azure.compute.VirtualMachineScaleSet("analogcompute/agents", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  vmScaleSetName: "analogcompute-agents",
  overprovision: false,
  sku: {
    capacity: agentCount,
    name: azure.compute.VirtualMachineSizeTypes.Standard_B2s,
  },
  upgradePolicy: {
    mode: azure.compute.UpgradeMode.Manual,
  },
  orchestrationMode: azure.compute.OrchestrationMode.Uniform,
  identity: {
    type: azure.compute.ResourceIdentityType.SystemAssigned_UserAssigned,
    userAssignedIdentities: [
      k3sAgentIdentity.id,
    ],
  },
  virtualMachineProfile: {
    storageProfile: {
      osDisk: {
        createOption: azure.compute.DiskCreateOption.FromImage,
        managedDisk: {
          storageAccountType: azure.compute.StorageAccountTypes.StandardSSD_LRS,
        },
      },
      imageReference: {
        publisher: "Canonical",
        offer: "0001-com-ubuntu-server-jammy",
        sku: "22_04-lts-gen2",
        version: "latest",
      },
    },
    networkProfile: {
      networkInterfaceConfigurations: [{
        name: 'analogcompute-agent-nic-01',
        primary: true,
        networkSecurityGroup: {
          id: agentNodeNsg.id,
        },
        ipConfigurations: [{
          name: 'analogcompute-agent-ipcfg-01',
          subnet: {
            id: subnets["k3s-secondary"].id?.apply(id => id!),
          },
        }],
      }],
    },
    osProfile: {
      computerNamePrefix: "analogcompute-a-",
      adminUsername: "azureuser",
      linuxConfiguration: {
        disablePasswordAuthentication: true,
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
    userData: cloudInit.apply(cloudInit => Buffer.from(cloudInit).toString('base64')),
  },
});