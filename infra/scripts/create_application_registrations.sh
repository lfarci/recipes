# Retrieves the Azure AD application registration details for a given application name.
#
# Arguments:
#   applicationName (string): The name of the Azure AD application.
#
# Returns:
#   JSON object containing the objectId and clientId of the application registration.
get_app_registration() {
    local applicationName=$1

    if [ -z "$applicationName" ]; then
        echo "$FUNCNAME: applicationName parameter must be provided."
        exit 1
    fi

    local application=$(az ad app list --display-name "$applicationName" --query "[0].{objectId: id, clientId: appId}" -o json | jq -c)

    echo $application
}

# Creates an Azure AD application registration if it does not already exist.
# 
# Parameters:
#   applicationName (string): The name of the application to register.
# 
# Returns:
#   JSON object containing the objectId and clientId of the application registration.
create_app_registration() {
    local applicationName=$1

    if [ -z "$applicationName" ]; then
        echo "$FUNCNAME: applicationName parameter must be provided."
        exit 1
    fi

    local application=$(get_app_registration $applicationName)

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to get application registration."
        exit 1
    fi

    if [ -n "$application" ]; then
        echo $application
        return
    fi

    response=$(az ad app create --display-name "$applicationName")

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to create a new application registration named $applicationName."
        exit 1
    fi

    local objectId=$(jq -r '.id' <<< "$response")
    local clientId=$(jq -r '.appId' <<< "$response")

    local application=$(jq -c -n --arg id $objectId --arg appId $clientId '{objectId: $id, clientId: $appId}')

    # A service principal is required to complete the application registration. It is used to grant permissions to the client application.
    az ad sp create --id $clientId --only-show-errors >> /dev/null

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to create a service principal for application ID $clientId."
        exit 1
    fi

    echo $application
}

# Creates a new client secret for an Azure AD application registration.
#
# Parameters:
#   clientId (string): The client ID of the Azure AD application registration.
#   secretName (string): The display name for the new client secret.
#
# Returns:
#   The newly created client secret value.
create_app_registration_secret() {
    local clientId=$1
    local secretName=$2

    if [ -z "$clientId" ]; then
        echo "$FUNCNAME: clientId parameter must be provided."
        exit 1
    fi

    if [ -z "$secretName" ]; then
        echo "$FUNCNAME: secretName parameter must be provided."
        exit 1
    fi

    local clientSecret=$(az ad app credential reset --id "$clientId" --display-name "$secretName" --query "password" -o "tsv" --only-show-errors)

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to create a new client secret for client ID $clientId."
        exit 1
    fi

    echo $clientSecret
}

store_secret_in_keyvault() {
    local keyVaultName=$1
    local secretName=$2
    local secretValue=$3

    if [ -z "$keyVaultName" ]; then
        echo "$FUNCNAME: keyVaultName parameter must be provided."
        exit 1
    fi

    if [ -z "$secretName" ]; then
        echo "$FUNCNAME: secretName parameter must be provided."
        exit 1
    fi

    if [ -z "$secretValue" ]; then
        echo "$FUNCNAME: secretValue parameter must be provided."
        exit 1
    fi

    az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretValue --only-show-errors >> /dev/null

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to set secret in Key Vault: $keyVaultName."
        exit 1
    fi
}

expose_an_api() {
    local objectId=$1
    local clientId=$2

    if [ -z "$objectId" ]; then
        echo "$FUNCNAME: objectId parameter must be provided."
        exit 1
    fi

    if [ -z "$clientId" ]; then
        echo "$FUNCNAME: clientId parameter must be provided."
        exit 1
    fi

    az ad app update --id $objectId --identifier-uris "api://$clientId"

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to expose an API for application ID $objectId."
        exit 1
    fi
}

add_redirect_uri() {
    local clientId=$1
    local uri=$2

    if [ -z "$clientId" ]; then
        echo "$FUNCNAME: clientId parameter must be provided."
        exit 1
    fi

    if [ -z "$uri" ]; then
        echo "$FUNCNAME: uri parameter must be provided."
        exit 1
    fi

    # Get string array of existing redirect URIs
    existing_redirect_uris=$(az ad app show --id $clientId --query "[web.redirectUris]" --output tsv)

    # Check if the new URI is already in the list
    if [[ $existing_redirect_uris == *$uri* ]]; then
        printf "\nThe URI $uri is already in the list"
    else
        printf "\nAdding the URI $uri to the list"
        az ad app update --id $clientId --web-redirect-uris $existing_redirect_uris $uri
    fi
}

add_graph_permissions() {
    local clientId=$1
    local graphApiId="00000003-0000-0000-c000-000000000000"
    local userReadPermissionId="a154be20-db9c-4678-8ab7-66f6cc099a59"
    local directoryReadPermissionId="06da0dbc-49e2-44d2-8312-53f166ab848a"

    if [ -z "$clientId" ]; then
        echo "$FUNCNAME: clientId parameter must be provided."
        exit 1
    fi

    local existing_permissions=$(az ad app permission list --id $clientId --query "[].resourceAccess[].id" -o tsv)
    local to_add_permissions=()

    if [[ $existing_permissions == *"$directoryReadPermissionId"* ]]; then
        echo "The permission $directoryReadPermissionId is already set. It won't be added again."
    else
        to_add_permissions+=($directoryReadPermissionId) # Directory.Read.All
    fi

    if [[ $existing_permissions == *"$userReadPermissionId"* ]]; then
        echo "The permission $userReadPermissionId is already set. It won't be added again."
    else
        to_add_permissions+=($userReadPermissionId) # User.Read.All
    fi

    if [ ${#to_add_permissions[@]} -eq 0 ]; then
        echo "No new permissions to add."
    else
        echo "Adding API permissions: ${to_add_permissions[@]}"

        az ad app permission add --id $clientId --api $graphApiId --api-permissions "${to_add_permissions[0]}=Scope" "${to_add_permissions[1]}=Scope" --only-show-errors

        if [ $? -ne 0 ]; then
            echo "$FUNCNAME: failed to add API permissions to application ID $clientId."
            exit 1
        fi
    fi

    # echo "Granting API permissions to application ID $clientId."

    # az ad app permission grant --id $clientId --api $graphApiId --scope "Directory.Read.All" "User.Read.All" --only-show-errors >> /dev/null

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to grant API permissions to application ID $clientId."
        exit 1
    fi

    echo "API permissions added and granted successfully."
}

if [ -z "$ApplicationName" ]; then
    echo "Error: ApplicationName environment variables must be set."
    exit 1
fi

if [ -z "$KeyVaultName" ]; then
    echo "Error: KeyVaultName environment variables must be set."
    exit 1
fi

if [ -z "$RedirectUri" ]; then
    echo "Error: RedirectUri environment variables must be set."
    exit 1
fi

printf "Starting executiing script to create application registration (command line call: $0).\n"
printf "\n- Application name: $ApplicationName"
printf "\n- Key vault name: $KeyVaultName"
printf "\n- Redirect uri is set to: $RedirectUri\n"

application=$(create_app_registration $ApplicationName)

if [ $? -ne 0 ]; then
    printf "\nFailed to create application registration."
    exit 1
else
    printf "\nApplication registration named $ApplicationName created successfully."
fi

clientId=$(jq -r '.clientId' <<< "$application")
objectId=$(jq -r '.objectId' <<< "$application")

if [ -z "$clientId" ]; then
    printf "\nFailed to retrieve client ID for application registration named $ApplicationName."
    exit 1
else
    printf "\nClient ID for application registration named $ApplicationName is $clientId."
fi

if [ -z "$objectId" ]; then
    printf "\nFailed to retrieve object ID for application registration named $ApplicationName."
    exit 1
else
    printf "\nObject ID for application registration named $ApplicationName is $objectId."
fi

expose_an_api $objectId $clientId

if [ $? -ne 0 ]; then
    printf "\nFailed to expose an API for application ID $objectId."
    exit 1
else
    printf "\nAPI exposed successfully."
fi

add_redirect_uri $clientId $RedirectUri

if [ $? -ne 0 ]; then
    printf "\nFailed to add redirect URI for application ID $clientId."
    exit 1
else
    printf "\nRedirect URI added successfully: $RedirectUri."
fi

clientSecret=$(create_app_registration_secret $clientId "ApiSecret")

if [ $? -ne 0 ]; then
    printf "\nFailed to create client secret for application ID $clientId."
    exit 1
else
    printf "\nClient secret named ApiSecret created successfully for application ID $clientId."
fi

store_secret_in_keyvault $KeyVaultName "Api--ClientSecret" $clientSecret

if [ $? -ne 0 ]; then
    printf "\nFailed to store client secret for application ID $clientId in Key Vault named $KeyVaultName."
    exit 1
else
    printf "\nClient secret named Api--ClientSecret created successfully in Key Vault named $KeyVaultName."
fi

unset $clientSecret
printf "\nClient secret saved in key vault: $KeyVaultName"

add_graph_permissions $clientId

if [ $? -ne 0 ]; then
    printf "\nFailed to add graph permissions for application ID $clientId."
    exit 1
fi

outputJson=$(jq -n \
                --arg applicationObjectId "$objectId" \
                --arg applicationClientId "$clientId" \
                --arg clientSecretName "Api--ClientSecret" \
                '{applicationObjectId: $applicationObjectId, applicationClientId: $applicationClientId, clientSecretName: $clientSecretName }' )

echo "Output: $outputJson"
    
echo $outputJson > $AZ_SCRIPTS_OUTPUT_PATH