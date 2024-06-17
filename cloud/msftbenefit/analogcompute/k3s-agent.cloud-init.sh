#!/bin/bash

if [ "$IDENTITY_ID" == "" ]; then
  IDENTITY_ID="@IDENTITY_ID@"
fi

echo "Installing Azure CLI"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Authenticating with Azure CLI using managed identity $IDENTITY_ID"
az login --identity --username "$IDENTITY_ID" --allow-no-subscriptions

echo "Fetching k3s token"
az keyvault secret show --name k3s-token --vault-name analogcompute-vault --query value -o tsv > /tmp/k3s-token
sudo mv /tmp/k3s-token /etc/k3s-token

echo "Installing k3s"
curl -sfL https://get.k3s.io | sh -s - agent --token-file /etc/k3s-token --server "https://internal.analogrelay.cloud:6443"

echo "Dropping kubectl config"
az keyvault secret show --vault-name analogcompute-vault --name k3s-config --query value -o tsv | sed 's/127.0.0.1/analogcompute-p01.internal.analogrelay.cloud/g' > ~/.kube/config

echo "Downloading k3s-agent-shutdown.sh"
az storage blob download --account-name analogcompute --container-name scripts --name k3s-agent-shutdown.sh --file /tmp/k3s-agent-shutdown.sh
sudo mv /tmp/k3s-agent-shutdown.sh /usr/local/bin/k3s-agent-shutdown.sh