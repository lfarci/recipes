managedIdentityName='script-identity'
resourceGroupName='lfarci-recipes-test-5'
location='westeurope'
tenantId="ffa5591d-cae2-492c-8674-129a6be07489"

userAssignedIdentity=$(az identity create --name $managedIdentityName --resource-group $resourceGroupName --location $location)

managedIdentityObjectId=$(jq -r '.principalId' <<< "$userAssignedIdentity")


graphAppId='00000003-0000-0000-c000-000000000000' # This is a well-known Microsoft Graph application ID.
graphApiAppRoleName='Application.ReadWrite.All'
graphApiApplication=$(az ad sp list --filter "appId eq '$graphAppId'" --query "{ appRoleId: [0] .appRoles [?value=='$graphApiAppRoleName'].id | [0], objectId:[0] .id }" -o json)

# Get the app role for the Graph API.
graphServicePrincipalObjectId=$(jq -r '.objectId' <<< "$graphApiApplication")
graphApiAppRoleId=$(jq -r '.appRoleId' <<< "$graphApiApplication")

# Assign the role to the managed identity.
requestBody=$(jq -n \
                  --arg id "$graphApiAppRoleId" \
                  --arg principalId "$managedIdentityObjectId" \
                  --arg resourceId "$graphServicePrincipalObjectId" \
                  '{id: $id, principalId: $principalId, resourceId: $resourceId}' )

az rest -m post -u "https://graph.windows.net/$tenantId/servicePrincipals/$managedIdentityObjectId/appRoleAssignments?api-version=1.6" -b "$requestBody"