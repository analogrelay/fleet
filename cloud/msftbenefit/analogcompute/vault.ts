import * as azure from '@pulumi/azure-native';
import resourceGroup from './resourceGroup.js';
import { k3sServerIdentity, k3sAgentIdentity } from './identity.js';
import { analogDirectory, msftbenefit } from '../../global.js';

export const vault = new azure.keyvault.Vault("analogcompute/vault", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  vaultName: "analogcompute-vault",
  properties: {
    tenantId: analogDirectory.tenantId,
    sku: {
      family: azure.keyvault.SkuFamily.A,
      name: azure.keyvault.SkuName.Standard,
    },
    enabledForDiskEncryption: false,
    enabledForTemplateDeployment: false,
  },
}, { provider: msftbenefit });

export const ashleyCanWrite = new azure.keyvault.AccessPolicy("analogcompute/vault/ashleyCanWrite", {
  resourceGroupName: resourceGroup.name,
  vaultName: vault.name,
  policy: {
    tenantId: analogDirectory.tenantId,
    objectId: analogDirectory.users.ashley.principalId,
    permissions: {
      keys: [azure.keyvault.KeyPermissions.All, azure.keyvault.KeyPermissions.Purge],
      secrets: [azure.keyvault.SecretPermissions.All, azure.keyvault.SecretPermissions.Purge],
      certificates: [azure.keyvault.CertificatePermissions.All, azure.keyvault.CertificatePermissions.Purge],
    },
  }
}, { provider: msftbenefit });

export const k3sServerAccessPolicy = new azure.keyvault.AccessPolicy("analogcompute/vault/k3sServerAccessPolicy", {
  resourceGroupName: resourceGroup.name,
  vaultName: vault.name,
  policy: {
    tenantId: analogDirectory.tenantId,
    objectId: k3sServerIdentity.principalId,
    permissions: {
      keys: [],
      secrets: [azure.keyvault.SecretPermissions.Set, azure.keyvault.SecretPermissions.Get, azure.keyvault.SecretPermissions.List],
      certificates: [],
    },
  }
}, { provider: msftbenefit });

export const k3sAgentAccessPolicy = new azure.keyvault.AccessPolicy("analogcompute/vault/k3sAgentAccessPolicy", {
  resourceGroupName: resourceGroup.name,
  vaultName: vault.name,
  policy: {
    tenantId: analogDirectory.tenantId,
    objectId: k3sAgentIdentity.principalId,
    permissions: {
      keys: [],
      secrets: [azure.keyvault.SecretPermissions.Get, azure.keyvault.SecretPermissions.List],
      certificates: [],
    },
  }
}, { provider: msftbenefit });