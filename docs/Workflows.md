# Login to Azure using a service principal secret
Workflows will log into Azure using a [service principal secret](https://github.com/Azure/login#login-with-a-service-principal-secret). This is useful for running workflows in a CI/CD environment where you don't want to use an interactive login.

# Create a user-assigned managed identity from a bash script
```bash
az ad sp show --id <service-principal-id> --query objectId -o tsv
az role assignment create --assignee <service-principal-object-id> --role "Application.ReadWrite.OwnedBy"
```