import * as azure from '@pulumi/azure-native';
import { analogDirectory, msftbenefit } from '../global.js';

export const resourceGroup = new azure.resources.ResourceGroup("analogdev", {
  location: "westus3",
  resourceGroupName: "analogdev",
}, {
  provider: msftbenefit,
});

export const vnet = new azure.network.VirtualNetwork("analogdev/vnet", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  virtualNetworkName: "analogdev-vnet",
  addressSpace: {
      addressPrefixes: ["10.0.0.0/16"],
  },
  subnets: [
    {
      name: "machines",
      addressPrefix: "10.0.1.0/24",
    },
  ]
}, { 
  provider: msftbenefit,
});

export const subnets = vnet.subnets.apply(subnets => {
  if(!subnets) {
    return {};
  }

  return subnets.reduce((acc, subnet) => {
    if(subnet.name) {
      acc[subnet.name] = subnet;
    }
    return acc;
  }, {} as Record<string, azure.types.output.network.SubnetResponse>);
});

export const publicIp = new azure.network.PublicIPAddress("analogdev/p01/ip", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  publicIpAddressName: "analogdev-p01-ip",
  publicIPAllocationMethod: azure.network.IPAllocationMethod.Static,
  dnsSettings: {
      domainNameLabel: 'analogdev-p01',
  },
}, { provider: msftbenefit });

export const primaryNodeNsg = new azure.network.NetworkSecurityGroup("analogdev/vnet/primary-nsg", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  networkSecurityGroupName: "analogdev-primary-nsg",
  securityRules: [
    {
      name: "allow-ssh",
      priority: 1001,
      direction: "Inbound",
      access: "Allow",
      protocol: "Tcp",
      sourcePortRange: "*",
      destinationPortRange: "22",
      sourceAddressPrefix: "*",
      destinationAddressPrefix: "*",
    },
  ]
}, { provider: msftbenefit });

export const nic = new azure.network.NetworkInterface("analogdev/p01/nic", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  networkInterfaceName: "analogdev-p01-nic",
  networkSecurityGroup: {
    id: primaryNodeNsg.id,
  },
  ipConfigurations: [{
    name: 'analogdev-p01-ipcfg-01',
    privateIPAddress: "10.0.1.10", // Static assigned private IP.
    privateIPAllocationMethod: 'Static',
    subnet: {
      id: subnets["machines"].id?.apply(id => id!),
    },
    publicIPAddress: {
      id: publicIp.id,
    },
  }],
}, { provider: msftbenefit });

export const vm = new azure.compute.VirtualMachine("analogdev/p01/vm", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  vmName: "analogdev-p01",
  hardwareProfile: {
    vmSize: "Standard_D4ads_v5",
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
    computerName: "analogdev-p01",
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
          keyData: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORrQc/lWgw0lUGHrD/VUNxanWwTdppZuhUVmvBLPm13",
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
    type: azure.compute.ResourceIdentityType.SystemAssigned,
  },
}, { provider: msftbenefit });

new azure.devtestlab.Schedule("analogdev/p01/schedule", {
  resourceGroupName: resourceGroup.name,
  labName: "analogdev-lab",
  dailyRecurrence: {
    time: "20:00",
  },
  timeZoneId: "Pacific Standard Time",
  targetResourceId: vm.id,
  taskType: "ComputeVmShutdownTask",
  status: "Enabled",
}, { provider: msftbenefit });