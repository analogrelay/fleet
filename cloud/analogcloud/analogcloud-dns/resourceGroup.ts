import * as azure from '@pulumi/azure-native';
import { analogcloud } from '../../global.js';

export const resourceGroup = new azure.resources.ResourceGroup("analogcloud-dns", {
  location: "westus3",
  resourceGroupName: "analogcloud-dns",
}, {
  provider: analogcloud,
  protect: true, // Protected because there are resources in here that are not managed by Pulumi
});

export default resourceGroup;