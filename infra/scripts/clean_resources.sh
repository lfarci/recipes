while [[ "$#" -gt 0 ]]; do
    case $1 in
        --environment-tag) environment_tag="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$environment_tag" ]; then
    echo "The parameter --environment-tag is required."
    exit 1
fi

resource_group="lfarci-recipes-$environment_tag-rg"
site_name="lfarci-recipes-$environment_tag-site"
api_name="lfarci-recipes-$environment_tag-api"

# check if resource group exists
resource_groups=$(az group list --query "[?contains(name, '$resource_group')].name")

if [[ "$resource_groups" != *"$resource_group"* ]]; then
    echo "Resource group named $resource_group does not exist. Nothing to delete."
else
    echo "Deleting resource group named $resource_group..."
    az group delete --name $resource_group --yes

    if [[ $? -ne 0 ]]; then
        echo "Failed to delete resource group named $resource_group."
        exit 1
    else
        echo "Resource group named $resource_group was deleted successfully."
    fi
fi

echo "Fetching the deleted KeyVault for the resource group $resource_group..."
keyvault_name=$(az keyvault list-deleted --query "[?contains(properties.vaultId, '$resource_group')].name" --output tsv)

if [ $? -ne 0 ]; then
    echo "Failed to fetch the deleted KeyVault for the resource group $resource_group."
    exit 1
fi

if [ -z "$keyvault_name" ]; then
    echo "No KeyVault was found in the resource group $resource_group. Nothing to purge."
else
    echo "Purging KeyVault named $keyvault_name..."
    az keyvault purge --name $keyvault_name

    if [ $? -ne 0 ]; then
        echo "Failed to purge KeyVault named $keyvault_name."
        exit 1
    else
        echo "KeyVault named $keyvault_name was purged successfully."
    fi
fi

site_object_id=$(az ad app list --display-name $site_name --query '[].id' -o tsv)

if [ $? -ne 0 ]; then
    echo "Failed to fetch the object ID of the app registration named $site_name."
    exit 1
fi

api_object_id=$(az ad app list --display-name $api_name --query '[].id' -o tsv)

if [ $? -ne 0 ]; then
    echo "Failed to fetch the object ID of the app registration named $api_name."
    exit 1
fi

if [ -z "$site_object_id" ]; then
    echo "No app registration named $site_name was found. Nothing to delete."
else
    echo "Deleting app registration named $site_name..."
    echo "Object ID of the app registration named $site_name: $site_object_id"
    az ad app delete --id $site_object_id
    echo "App registration named $site_name was deleted successfully."
fi

if [ -z "$api_object_id" ]; then
    echo "No app registration named $api_name was found. Nothing to delete."
else
    echo "Deleting app registration named $api_name..."
    echo "Object ID of the app registration named $api_name: $api_object_id"
    az ad app delete --id $api_object_id
    echo "App registration named $api_name was deleted successfully."
fi
