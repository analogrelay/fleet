import { msftbenefit } from "../../global.js";
import resourceGroup from "./resourceGroup.js";
import * as azure from '@pulumi/azure-native';

export const vnet = new azure.network.VirtualNetwork("analogcompute/vnet", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  virtualNetworkName: "analogcompute-vnet",
  addressSpace: {
      addressPrefixes: ["10.0.0.0/16"],
  },
  subnets: [
    {
      name: "k3s-primary",
      addressPrefix: "10.0.1.0/24",
    },
    {
      name: "k3s-secondary",
      addressPrefix: "10.0.2.0/24",
    }
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

export const agentNodeNsg = new azure.network.NetworkSecurityGroup("analogcompute/vnet/agent-nsg", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  networkSecurityGroupName: "analogcompute-agent-nsg",
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
    }
  ]
}, { provider: msftbenefit });

export const primaryNodeNsg = new azure.network.NetworkSecurityGroup("analogcompute/vnet/primary-nsg", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  networkSecurityGroupName: "analogcompute-primary-nsg",
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
    {
      name: "allow-k8s",
      priority: 1002,
      direction: "Inbound",
      access: "Allow",
      protocol: "Tcp",
      sourcePortRange: "*",
      destinationPortRange: "6443",
      sourceAddressPrefix: "*",
      destinationAddressPrefix: "*",
    },
    {
      name: "allow-http",
      priority: 1003,
      direction: "Inbound",
      access: "Allow",
      protocol: "Tcp",
      sourcePortRange: "*",
      destinationPortRange: "80",
      sourceAddressPrefix: "*",
      destinationAddressPrefix: "*",
    },
    {
      name: "allow-https",
      priority: 1004,
      direction: "Inbound",
      access: "Allow",
      protocol: "Tcp",
      sourcePortRange: "*",
      destinationPortRange: "443",
      sourceAddressPrefix: "*",
      destinationAddressPrefix: "*",
    },
  ]
}, { provider: msftbenefit });

export const privateDns = new azure.network.PrivateZone("analogcompute/vnet/private-dns", {
  location: "Global",
  resourceGroupName: resourceGroup.name,
  privateZoneName: "internal.analogrelay.cloud",
}, { provider: msftbenefit });

new azure.network.VirtualNetworkLink("analogcompute/vnet/private-dns/link", {
  location: "Global",
  resourceGroupName: resourceGroup.name,
  virtualNetworkLinkName: "analogcompute-vnet-link",
  privateZoneName: privateDns.name,
  registrationEnabled: true,
  virtualNetwork: {
    id: vnet.id,
  },
}, { provider: msftbenefit });