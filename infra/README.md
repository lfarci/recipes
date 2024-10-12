```bash
managedIdentityName='script-identity'
resourceGroupName='lfarci-rg'
location='westeurope'

userAssignedIdentity=$(az identity create --name $managedIdentityName --resource-group $resourceGroupName --location $location)

managedIdentityObjectId=$(jq -r '.principalId' <<< "$userAssignedIdentity")
```