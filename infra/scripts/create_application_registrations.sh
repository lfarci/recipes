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

    existing_secret=$(az ad app credential list --id "$clientId" --query "[?displayName=='$secretName'].{value: secretText}" -o tsv --only-show-errors)

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to retrieve existing client secrets for client ID $clientId."
        exit 1
    fi

    if [ -n "$existing_secret" ]; then
        echo "$FUNCNAME: client secret with name $secretName already exists. It won't be reset."
        return
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

    existing_secret=$(az keyvault secret show --vault-name $keyVaultName --name $secretName --query "value" -o tsv --only-show-errors)

    if [ $? -eq 0 ]; then
        echo "$FUNCNAME: secret with name $secretName already exists in Key Vault $keyVaultName. It won't be stored."
        return
    fi

    echo "Storing secret in Key Vault: $keyVaultName"

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

    api=$(cat <<EOF
        {
            "oauth2PermissionScopes": [
                {
                    "id": "a7f3c80f-e49b-479a-8506-38c798584fa6",
                    "adminConsentDisplayName": "Access the recipes API",
                    "adminConsentDescription": "Allow the application to access the recipes API on behalf of the signed-in user.",
                    "userConsentDisplayName": "Access your recipes",
                    "userConsentDescription": "Allow the application to access the recipes API on your behalf.",
                    "type": "User",
                    "value": "access_as_user",
                    "isEnabled": true
                }
            ],
            "requestedAccessTokenVersion": 2
        }
EOF
    )

    existing_api=$(az ad app show --id $objectId  --query "api" --output json)

    if echo "$existing_api" | jq -e '.oauth2PermissionScopes[] | select(.value == "access_as_user")' > /dev/null; then
        echo "OAuth2 permission scope 'access_as_user' already exists. It will be disabled and re-added."

        az ad app update --id $objectId --set api="$(echo $api | jq '.oauth2PermissionScopes[0].isEnabled = false' )"

        if [ $? -ne 0 ]; then
            echo "$FUNCNAME: failed to disable existing OAuth2 permissions for application ID $objectId."
            exit 1
        fi

        echo "Existing OAuth2 permission scope 'access_as_user' disabled successfully."
    fi

    az ad app update --id $objectId --set api="$api"

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to set OAuth2 permissions for application ID $objectId."
        exit 1
    fi
}

add_redirect_uri() {
    local id=$1
    local uri=$2

    if [ -z "$id" ]; then
        echo "$FUNCNAME: id parameter must be provided."
        exit 1
    fi

    if [ -z "$uri" ]; then
        echo "$FUNCNAME: uri parameter must be provided."
        exit 1
    fi

    # Get string array of existing redirect URIs
    existing_redirect_uris=$(az ad app show --id $id --query "[spa.redirectUris]" --output tsv)

    # Check if the new URI is already in the list
    if [[ $existing_redirect_uris == *$uri* ]]; then
        printf "\nThe URI $uri is already in the list"
    else
        printf "\nAdding the URI $uri to the list for $id object ID."

        # Cannot set a redirect URI for a SPA. Issue: https://github.com/Azure/azure-cli/issues/25766
        # az ad app update --id $clientId --web-redirect-uris $existing_redirect_uris $uri

        az rest \
            --method "patch" \
            --uri "https://graph.microsoft.com/v1.0/applications/$id" \
            --headers "{'Content-Type': 'application/json'}" \
            --body "{'spa': {'redirectUris': [ '$uri' ]}}"
        
        if [ $? -ne 0 ]; then
            echo "$FUNCNAME: failed to add redirect URI for application ID $id."
            exit 1
        fi
    fi
}

add_graph_permissions() {
    local clientId=$1
    local graphApiId="00000003-0000-0000-c000-000000000000"
    local userReadPermissionId="e1fe6dd8-ba31-4d61-89e7-88639da4683d"
    local userReadBasicPermissionId="b340eb25-3456-403f-be2f-af7a0d370277"

    if [ -z "$clientId" ]; then
        echo "$FUNCNAME: clientId parameter must be provided."
        exit 1
    fi

    local existing_permissions=$(az ad app permission list --id $clientId --query "[].resourceAccess[].id" -o tsv)
    local to_add_permissions=()

    if [[ $existing_permissions == *"$userReadBasicPermissionId"* ]]; then
        echo "The permission $userReadBasicPermissionId is already set. It won't be added again."
    else
        to_add_permissions+=($userReadBasicPermissionId) # User.ReadBasic.All
    fi

    if [[ $existing_permissions == *"$userReadPermissionId"* ]]; then
        echo "The permission $userReadPermissionId is already set. It won't be added again."
    else
        to_add_permissions+=($userReadPermissionId) # User.Read
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

    echo "API permissions added successfully."
}

add_recipes_api_permissions() {
    local site_client_id=$1
    local api_client_id=$2

    local access_as_user_permission_id="a7f3c80f-e49b-479a-8506-38c798584fa6"

    if [ -z "$site_client_id" ]; then
        echo "$FUNCNAME: Static site client ID parameter must be provided."
        exit 1
    fi

    if [ -z "$api_client_id" ]; then
        echo "$FUNCNAME: API client ID parameter must be provided."
        exit 1
    fi

    local existing_permissions=$(az ad app permission list --id $site_client_id --query "[].resourceAccess[].id" -o tsv)

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to find existing permissions for the static site. Client ID: $site_client_id."
        exit 1
    fi

    if [[ $existing_permissions == *"$access_as_user_permission_id"* ]]; then
        echo "The permission $access_as_user_permission_id is already set. It won't be added again."
        return
    fi

    echo "Adding API permissions: $access_as_user_permission_id"

    az ad app permission add --id $site_client_id --api $api_client_id --api-permissions "$access_as_user_permission_id=Scope" --only-show-errors

    if [ $? -ne 0 ]; then
        echo "$FUNCNAME: failed to add API permissions to application ID $site_client_id."
        exit 1
    fi

    echo "API permissions added successfully."
}

if [ -z "$ApiName" ]; then
    echo "Error: ApiName environment variables must be set."
    exit 1
fi

if [ -z "$SiteName" ]; then
    echo "Error: SiteName environment variables must be set."
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
printf "\n- API name: $ApiName"
printf "\n- Key vault name: $KeyVaultName"
printf "\n- Redirect uri is set to: $RedirectUri\n"

api_json=$(create_app_registration $ApiName)

if [ $? -ne 0 ]; then
    printf "\nFailed to create application registration for the API."
    exit 1
else
    printf "\nApplication registration named $ApiName created successfully for the API."
fi

api_client_id=$(jq -r '.clientId' <<< "$api_json")
api_object_id=$(jq -r '.objectId' <<< "$api_json")

if [ -z "$api_client_id" ]; then
    printf "\nFailed to retrieve client ID for application registration named $ApiName."
    exit 1
else
    printf "\nClient ID for application registration named $ApiName is $api_client_id."
fi

if [ -z "$api_object_id" ]; then
    printf "\nFailed to retrieve object ID for application registration named $ApiName."
    exit 1
else
    printf "\nObject ID for application registration named $ApiName is $api_object_id."
fi

expose_an_api $api_object_id $api_client_id

if [ $? -ne 0 ]; then
    printf "\nFailed to expose an API for application ID $api_object_id."
    exit 1
else
    printf "\nAPI exposed successfully."
fi

clientSecret=$(create_app_registration_secret $api_client_id "ApiSecret")

if [ $? -ne 0 ]; then
    printf "\nFailed to create client secret for application ID $api_client_id."
    exit 1
else
    printf "\nClient secret named ApiSecret created successfully for application ID $api_client_id."
fi

store_secret_in_keyvault $KeyVaultName "Api--ClientSecret" $clientSecret

if [ $? -ne 0 ]; then
    printf "\nFailed to store client secret for application ID $api_client_id in Key Vault named $KeyVaultName."
    exit 1
else
    printf "\nClient secret named Api--ClientSecret created successfully in Key Vault named $KeyVaultName."
fi

unset $clientSecret
printf "\nClient secret saved in key vault: $KeyVaultName"

add_graph_permissions $api_client_id

if [ $? -ne 0 ]; then
    printf "\nFailed to add graph permissions for application ID $api_client_id."
    exit 1
fi

site_json=$(create_app_registration $SiteName)

if [ $? -ne 0 ]; then
    printf "\nFailed to create application registration for the static site."
    exit 1
else
    printf "\nApplication registration named $SiteName created successfully for the static site."
fi

site_client_id=$(jq -r '.clientId' <<< "$site_json")
site_object_id=$(jq -r '.objectId' <<< "$site_json")

if [ -z "$site_client_id" ]; then
    printf "\nFailed to retrieve client ID for application registration named $SiteName."
    exit 1
else
    printf "\nClient ID for application registration named $SiteName is $site_client_id."
fi

if [ -z "$site_object_id" ]; then
    printf "\nFailed to retrieve object ID for application registration named $SiteName."
    exit 1
else
    printf "\nObject ID for application registration named $SiteName is $site_object_id."
fi

add_recipes_api_permissions $site_client_id $api_client_id

if [ $? -ne 0 ]; then
    printf "\nFailed to add API permissions for application ID $site_client_id."
    exit 1
else
    printf "\nAPI permissions added successfully for application ID $site_client_id."
fi

add_graph_permissions $site_client_id

if [ $? -ne 0 ]; then
    printf "\nFailed to add graph permissions for application ID $site_client_id."
    exit 1
else
    printf "\nGraph permissions added successfully for application ID $site_client_id."
fi

add_redirect_uri $site_object_id $RedirectUri

if [ $? -ne 0 ]; then
    printf "\nFailed to add redirect URI for application ID $api_client_id."
    exit 1
else
    printf "\nRedirect URI added successfully: $RedirectUri."
fi

outputJson=$(jq -n \
                --arg apiClientId "$api_client_id" \
                --arg siteClientId "$site_client_id" \
                '{apiClientId: $apiClientId, siteClientId: $siteClientId }' )

echo "Output: $outputJson"
    
echo $outputJson > $AZ_SCRIPTS_OUTPUT_PATH