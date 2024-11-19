# Infrastructure Deployment Guide
This guide explains how to deploy Azure resources using Bicep templates and set up a managed identity for deployment scripts.

## Prerequisites
> ℹ️ Prerequisites setup is automatically run the by a GitHub Action workflow. This section is for manual setup.

### Create a Resource Group

A new resource group should be created in your Azure tenant. You can use the Azure Portal or the Azure CLI to create a resource group. Here's an example using the Azure CLI:

```bash
az group create --name <resource-group-name> --location <location>
```

### Creating a Managed Identity for Microsoft Entra ID Setup

A script is available to create a user-assigned managed identity, which will be used to authenticate the Microsoft Entra ID setup process. The script is located in `infra/scripts` directory and named `create_script_identity.sh`. Here's what the script does:

1. Creates a user-assigned managed identity in your resource group
2. Assigns the following Microsoft Graph API permissions:
    1. `Application.ReadWrite.All`: Allows the script to read and write all applications
    2. `Directory.ReadWrite.All`: Allows the script to read and write all directory data
    3. `User.Read.All`: Allows the script to read all users

You can invoke the script using the following command:

```bash
create_script_identity.sh --managed-identity-name <name> --resource-group-name <name> --location <location> --tenant-id <tenant-id>
```

Pass the created managed identity name to the Bicep template for authentication when running the Entra ID setup script.

## Deploy Azure Resources

Deployment of Azure resources is done using a Bicep template. The template is located in the `infra` directory and named `main.bicep`. Parameters are defined in `dev.bicepparam` file.

### Parameters
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `applicationName` | `string` | Yes | The name of the application. |
| `deploymentScriptIdentityName` | `string` | Yes | The name of the managed identity (see prerequisites). |
| `location` | `string` | No | The location where the resources will be deployed. Default is the resource group location. |
| `environmentName` | `string` | Yes | The environment name. |
| `adminUserObjectId` | `string` | Yes | The object ID of the admin user. |
| `entraIdInstance` | `string` | Yes | The name of the Microsoft Entra ID instance. |

### Resources
| Name | Type | Description |
|------|------|-------------|
| `lfarci-recipes-<env>-api-plan` | `Microsoft.Web/serverfarms` | The App Service Plan for the API. |
| `lfarci-recipes-<env>-api` | `Microsoft.Web/sites` | The App Service for the API. |
| `lfarci-recipes-<env>-site` | `Microsoft.Web/sites` | The Static Web App for the web frontend. |
| `lfarci-recipes-<env>-cosmos-db` | `Microsoft.DocumentDB/databaseAccounts` | The Cosmos DB account. |
| `app-<uniqueString(resourceGroup().id)>-kv` | `Microsoft.KeyVault/vaults` | The Key Vault. |

### Deploy the Bicep template
```bash
az deployment group create \
    --resource-group "MyResourceGroup" \
    --template-file "main.bicep" \
    --parameters "dev.bicepparam" \
    --parameters environmentName="dev"
```