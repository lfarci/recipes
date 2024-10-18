# Create the application.
application=$(az ad app create --display-name $ApplicationName)
applicationObjectId=$(jq -r '.id' <<< "$application")
applicationClientId=$(jq -r '.appId' <<< "$application")

printf "\nApplication created with object id: $applicationObjectId and client id: $applicationClientId"

# Create an application secret.
secretName="$ApplicationName-secret"
clientSecret=$(az ad app credential reset --id "$applicationClientId" --display-name "$secretName" --query "password" -o "tsv")
printf "\nClient secret created with name: $secretName"
az keyvault secret set --vault-name $KeyVaultName --name $secretName --value "$clientSecret"

if [ $? -ne 0 ]; then
    echo "Failed to set secret in Key Vault: $KeyVaultName"
    exit 1
fi

unset $clientSecret
printf "\nClient secret saved in key vault: $KeyVaultName"

# Create a service principal for the application.
servicePrincipal=$(az ad sp create --id $applicationObjectId)
servicePrincipalObjectId=$(jq -r '.id' <<< "$servicePrincipal")

# Save the important properties as depoyment script outputs.
outputJson=$(jq -n \
                --arg applicationObjectId "$applicationObjectId" \
                --arg applicationClientId "$applicationClientId" \
                --arg servicePrincipalObjectId "$servicePrincipalObjectId" \
                --arg clientSecretName "$secretName" \
                '{applicationObjectId: $applicationObjectId, applicationClientId: $applicationClientId, servicePrincipalObjectId: $servicePrincipalObjectId, clientSecretName: $clientSecretName }' )
    
echo $outputJson > $AZ_SCRIPTS_OUTPUT_PATH