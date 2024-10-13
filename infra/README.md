# Deploy the Bicep template
```bash
az deployment group create --resource-group $resourceGroupName --template-file main.bicep --parameters dev.bicepparam
```

# Create the deployment script identity
```bash
managedIdentityName='script-identity'
resourceGroupName='lfarci-rg'
location='westeurope'

userAssignedIdentity=$(az identity create --name $managedIdentityName --resource-group $resourceGroupName --location $location)

managedIdentityObjectId=$(jq -r '.principalId' <<< "$userAssignedIdentity")
```