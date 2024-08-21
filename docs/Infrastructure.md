# Workflow

`recipes.infra.yml` is responsible for deploying resources to Azure.

## Login
The wokflow authenticates to the Azure resources manager using the `Azure/login` GitHub action via a [Service Principal Secret](https://github.com/Azure/login?tab=readme-ov-file#login-with-a-service-principal-secret).

Personally the app registration I created using the linked documentation was missing a role assignment.

I added using

```bash
az role assignment create --assignee "<clientId>" --role "Contributor" --scope "/subscriptions/<id>"
```