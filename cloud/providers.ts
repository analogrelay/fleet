import * as azure from "@pulumi/azure-native";

export const analogcloud = new azure.Provider("analogcloud", {
  subscriptionId: "466cf680-808d-4446-94b3-f367eaa60ba1",
});

export const msftbenefit = new azure.Provider("msftbenefit", {
  subscriptionId: "90f364ed-0f93-4e4c-ae02-14180320799a",
});