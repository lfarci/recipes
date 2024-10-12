#!/bin/bash
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <keyVaultName> <clientName>"
    exit 1
fi

keyVaultName="$1"
clientName="$2"

clientSecretName="$clientName-secret"

clientId=$(az ad app create --display-name "$clientName" --query "appId" -o "tsv")
clientSecret=$(az ad app credential reset --id "$clientId" --display-name "$clientSecretName" --query "password" -o "tsv")

az keyvault secret set --vault-name $keyVaultName --name "$clientName-secret" --value "$clientSecret"

unset $clientSecret

output=$(jq -n --arg clientId "$clientId")

echo $output > $AZ_SCRIPTS_OUTPUT_PATH