# Workflow

`recipes.infra.yml` is responsible for deploying resources to Azure.

## Login
The wokflow authenticates to the Azure resources manager using the `Azure/login` GitHub action via a [Service Principal Secret](https://github.com/Azure/login?tab=readme-ov-file#login-with-a-service-principal-secret).

Personally the app registration I created using the linked documentation was missing a role assignment.

I added using

```bash
az role assignment create --assignee "<clientId>" --role "Contributor" --scope "/subscriptions/<id>"
```


## Secrets

| Name                              | Description                                                                                       |
| --------------------------------- | ------------------------------------------------------------------------------------------------- |
| `ENTRA_ID_CLIENT_SECRET`          | Connect to Entra ID and find one of the client secret from the expected application registration. |
| `AZURE_CREDENTIALS`               | JSON structure as mentioned in the `azure\login` GitHub action documentation.                     |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | The token can be read from the deployed static web app overview page.                             |
| `AZURE_WEBAPP_PUBLISH_PROFILE`    | The publish profile can be downloaded from the Azure Portal web app overview page.                |


## Flow
1. Configure the minimum permissions for the Bicep file to be able to run the [deployment script](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep?tabs=CLI).

1. Create an application registration in Azure Entra ID and get the client ID.
    1. This can be automates using a Azure CLI or PowerShell script.
    2. The script should create the application with a secret and API scopes.
    3. The redirect URI should be set once the frontend application is deployed.

2. Create Cosmos DB instance and get the connection string.
3. Pass the connection string to the Azure App Service and set it as an environment variable named `RecipesDocumentDatabase`.
4. Read the Azure App Service URL and pass it to the frontend application.


### Deployment script 
The deployment script is responsible for deploying the resources to Azure. The script is written in Bicep and can be found in the `infra` directory.

[Sample (Use a deployment script to create Azure AD objects)](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.resources/deployment-script-azcli-graph-azure-ad)
[Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep#azurecliscriptproperties)