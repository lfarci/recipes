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