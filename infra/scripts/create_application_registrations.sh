if [ -z "$ApplicationName" ]; then
    echo "Error: ApplicationName environment variables must be set."
    exit 1
fi

if [ -z "$KeyVaultName" ]; then
    echo "Error: KeyVaultName environment variables must be set."
    exit 1
fi

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

    az keyvault secret set --vault-name $keyVaultName --name $secretName --value $secretValue

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

application=$(create_app_registration $ApplicationName)

if [ $? -ne 0 ]; then
    echo "Failed to create application registration: $ApplicationName"
    exit 1
fi

clientId=$(jq -r '.clientId' <<< "$application")
objectId=$(jq -r '.objectId' <<< "$application")

clientSecret=$(create_app_registration_secret $clientId "Secret")

if [ $? -ne 0 ]; then
    echo "Failed to create client secret for application: $ApplicationName"
    exit 1
fi

store_secret_in_keyvault $KeyVaultName "Api--ClientSecret" $clientSecret

if [ $? -ne 0 ]; then
    echo "Failed to store client secret in Key Vault: $KeyVaultName"
    exit 1
fi

unset $clientSecret
printf "\nClient secret saved in key vault: $KeyVaultName"

expose_an_api $objectId $clientId

if [ $? -ne 0 ]; then
    echo "Failed to expose an API for application: $ApplicationName"
    exit 1
fi

echo "API exposed successfully."

# Create a service principal for the application.
servicePrincipal=$(az ad sp create --id $objectId)
servicePrincipalObjectId=$(jq -r '.id' <<< "$servicePrincipal")

# Add an application ID URI to the application.
az ad app update --id $objectId --identifier-uris "api://$servicePrincipalObjectId"

# Save the important properties as depoyment script outputs.
outputJson=$(jq -n \
                --arg applicationObjectId "$objectId" \
                --arg applicationClientId "$clientId" \
                --arg servicePrincipalObjectId "$servicePrincipalObjectId" \
                --arg clientSecretName "Secret" \
                '{applicationObjectId: $applicationObjectId, applicationClientId: $applicationClientId, servicePrincipalObjectId: $servicePrincipalObjectId, clientSecretName: $clientSecretName }' )
    
echo $outputJson > $AZ_SCRIPTS_OUTPUT_PATH