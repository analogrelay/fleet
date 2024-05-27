import * as azuread from "@pulumi/azuread";
import * as azure from "@pulumi/azure-native";
import * as random from "@pulumi/random";
import resourceGroup from "./msftbenefit/analogcompute/resourceGroup.js";
import { ashleyCanWrite, vault } from "./msftbenefit/analogcompute/vault.js";
import { analogDirectory, msftbenefit } from "./global.js";

export const authApp = new azuread.Application("analogdirectory/apps/auth", {
  displayName: "analogcloud-auth",
  owners: [
    analogDirectory.users.ashley.principalId,
  ],
  signInAudience: "AzureADMyOrg",
  web: {
    homepageUrl: "https://analogrelay.cloud",
    logoutUrl: "https://auth.analogrelay.cloud/_oauth/logout",
    redirectUris: [
      "https://auth.analogrelay.cloud/_oauth",
    ],
  }
});

const authAppPassword = new azuread.ApplicationPassword("analogdirectory/apps/auth/traefik-forward-auth-password", {
  applicationId: authApp.id,
  endDate: "2024-11-29T00:00:00Z",
});

new azure.keyvault.Secret("analogcompute/vault/auth-client-secret", {
  resourceGroupName: resourceGroup.name,
  vaultName: vault.name,
  secretName: "auth-client-secret",
  properties: {
    value: authAppPassword.value,
  },
}, { 
  provider: msftbenefit,
  dependsOn: [ashleyCanWrite]
});

const authAppJwtSecret = new random.RandomPassword("analogdirectory/apps/auth/traefik-forward-auth-jwt-secret", {
  length: 32,
  special: false,
  keepers: {
    version: "v1",
  }
});

new azure.keyvault.Secret("analogcompute/vault/auth-jwt-secret", {
  resourceGroupName: resourceGroup.name,
  vaultName: vault.name,
  secretName: "auth-jwt-secret",
  properties: {
    value: authAppJwtSecret.result,
  },
}, { 
  provider: msftbenefit,
  dependsOn: [ashleyCanWrite]
});

