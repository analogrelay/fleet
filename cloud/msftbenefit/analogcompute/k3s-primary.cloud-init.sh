#!/bin/bash

if [ "$IDENTITY_ID" == "" ]; then
  IDENTITY_ID="@IDENTITY_ID@"
fi

if [ "$INTERNAL_DNS_NAME" == "" ]; then
  INTERNAL_DNS_NAME="analogcompute-p01.internal.analogrelay.cloud"
fi

if [ "$AZURE_DNS_NAME" == "" ]; then
  AZURE_DNS_NAME="@AZURE_DNS_NAME@"
fi

if [ "$PUBLIC_IP" == "" ]; then
  PUBLIC_IP="@PUBLIC_IP@"
fi

echo "Installing Azure CLI"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Authenticating with Azure CLI using managed identity $IDENTITY_ID"
az login --identity --username "$IDENTITY_ID" --allow-no-subscriptions

echo "Fetching k3s token"
az keyvault secret show --name k3s-token --vault-name analogcompute-vault --query value -o tsv > /tmp/k3s-token
sudo mv /tmp/k3s-token /etc/k3s-token

echo "Installing k3s"
curl -sfL https://get.k3s.io | sh -s - server \
  --token-file /etc/k3s-token \
  --node-external-ip "$PUBLIC_IP" \
  --node-label "svccontroller.k3s.cattle.io/enablelb=true" \
  --tls-san analogrelay.cloud \
  --tls-san "$INTERNAL_DNS_NAME" \
  --tls-san "$AZURE_DNS_NAME" \
  --tls-san "$PUBLIC_IP"

echo "Fetching kubeconfig and storing in keyvault"
sudo cp /etc/rancher/k3s/k3s.yaml k3s.yaml
sudo chown azureuser:azureuser k3s.yaml
az keyvault secret set --vault-name analogcompute-vault --name k3s-config --file k3s.yaml > /dev/null
rm k3s.yaml
