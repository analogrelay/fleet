import * as azuread from "@pulumi/azuread";
import * as azure from "@pulumi/azure-native";

export const analogDirectory = {
  tenantId: "2be5c49d-d8ac-4700-a8a7-10668c406a70",
  users: {
    ashley: {
      principalId: "e48d9318-160b-4abc-99ef-b561a9d8d9c0",
    },
  }
}

export const currentClient = azuread.getClientConfig();

export const analogcloud = new azure.Provider("analogcloud", {
  subscriptionId: "466cf680-808d-4446-94b3-f367eaa60ba1",
});

export const msftbenefit = new azure.Provider("msftbenefit", {
  subscriptionId: "90f364ed-0f93-4e4c-ae02-14180320799a",
});