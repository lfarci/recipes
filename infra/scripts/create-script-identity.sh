while [[ "$#" -gt 0 ]]; do
    case $1 in
        --managed-identity-name) managedIdentityName="$2"; shift ;;
        --resource-group-name) resourceGroupName="$2"; shift ;;
        --location) location="$2"; shift ;;
        --tenant-id) tenantId="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$resourceGroupName" ] || [ -z "$location" ] || [ -z "$tenantId" ]; then
    echo "All parameters --resource-group-name, --location, and --tenant-id are required."
    exit 1
fi

if [ -z "$managedIdentityName" ]; then
    managedIdentityName='script-identity'
    echo "No --managed-identity-name specified. Using default name: $managedIdentityName"
fi

echo "Current user"
currentUser=$(az account show -o json)

echo "Service principal"
servicePrincipal=$(az ad sp list --display-name GitHub-Actions --query "[].{displayName:displayName, appId:appId, id:id}" -o json)

echo $servicePrincipal

echo "Creating managed identity $managedIdentityName in resource group $resourceGroupName in location $location for tenant $tenantId."
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