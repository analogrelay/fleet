import * as azure from '@pulumi/azure-native';
import { analogDirectory, msftbenefit } from '../../global.js';

export const resourceGroup = new azure.resources.ResourceGroup("analogcompute", {
  location: "westus2",
  resourceGroupName: "analogcompute",
}, {
  provider: msftbenefit,
});

new azure.authorization.RoleAssignment("analogcompute/ashley-can-login", {
  principalId: analogDirectory.users.ashley.principalId,
  principalType: azure.authorization.PrincipalType.User,
  roleAssignmentName: "1c0163c0-47e6-4577-8991-ea5c82e286e4",
  roleDefinitionId: "/providers/Microsoft.Authorization/roleDefinitions/1c0163c0-47e6-4577-8991-ea5c82e286e4",
  scope: resourceGroup.id,
}, { provider: msftbenefit });

export default resourceGroup;