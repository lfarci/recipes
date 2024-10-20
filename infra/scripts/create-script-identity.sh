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

if ! az group show --name "$resourceGroupName" &> /dev/null; then
    echo "Resource group $resourceGroupName does not exist."
    exit 1
fi

echo "Creating managed identity $managedIdentityName in resource group $resourceGroupName in location $location for tenant $tenantId."
userAssignedIdentity=$(az identity create --name $managedIdentityName --resource-group $resourceGroupName --location $location)
if [ $? -ne 0 ]; then
    echo "Failed to create managed identity."
    exit 1
fi

managedIdentityId=$(jq -r '.id' <<< "$userAssignedIdentity")
managedIdentityPrincipalId=$(jq -r '.principalId' <<< "$userAssignedIdentity")

if [ -z "$managedIdentityId" ]; then
    echo "Failed to retrieve managed identityID from the creation response."
    exit 1
fi

if [ -z "$managedIdentityPrincipalId" ]; then
    echo "Failed to retrieve managed identity principal ID from the creation response."
    exit 1
fi

# Makes sure the identity is created before assigning the role by querying the identity by object ID.
echo "Waiting for the managed identity to be created..."
timeout=30
elapsed=0
interval=5

while [ $elapsed -lt $timeout ]; do
    identityCheck=$(az identity show --ids "$managedIdentityId" --query "id" -o tsv)
    if [ -n "$identityCheck" ]; then
        echo "Managed identity $managedIdentityName has been created."
        break
    fi
    echo "Waiting for managed identity $managedIdentityName to be created..."
    sleep $interval
    elapsed=$((elapsed + interval))
done

if [ $elapsed -ge $timeout ]; then
    echo "Timed out waiting for managed identity $managedIdentityName to be created."
    exit 1
fi

graphAppId='00000003-0000-0000-c000-000000000000' # This is a well-known Microsoft Graph application ID.
graphApiAppRoleName='Application.ReadWrite.All'
graphApiApplication=$(az ad sp list --filter "appId eq '$graphAppId'" --query "{ appRoleId: [0] .appRoles [?value=='$graphApiAppRoleName'].id | [0], objectId:[0] .id }" -o json)

graphServicePrincipalObjectId=$(jq -r '.objectId' <<< "$graphApiApplication")
graphApiAppRoleId=$(jq -r '.appRoleId' <<< "$graphApiApplication")

if [ -z "$graphServicePrincipalObjectId" ] || [ -z "$graphApiAppRoleId" ]; then
    echo "Failed to retrieve Graph API application role details."
    exit 1
fi

requestBody=$(jq -n \
                  --arg id "$graphApiAppRoleId" \
                  --arg principalId "$managedIdentityPrincipalId" \
                  --arg resourceId "$graphServicePrincipalObjectId" \
                  '{principalId: $principalId, resourceId: $resourceId, appRoleId: $id}' )

echo "Assigning role to the managed identity..."
existingRoleAssignment=$(az rest -m get -u "https://graph.microsoft.com/v1.0/servicePrincipals/$managedIdentityId/appRoleAssignments" | jq -r ".value[] | select(.appRoleId == \"$graphApiAppRoleId\" and .principalId == \"$managedIdentityPrincipalId\")")

if [ -n "$existingRoleAssignment" ]; then
    echo "Role assignment already exists for the managed identity."
else
    az rest -m post -u "https://graph.microsoft.com/v1.0/servicePrincipals/$managedIdentityId/appRoleAssignments" -b "$requestBody"
    if [ $? -ne 0 ]; then
        echo "Failed to assign role to the managed identity."
        exit 1
    fi
fi

echo "Managed identity creation and role assignment completed successfully."