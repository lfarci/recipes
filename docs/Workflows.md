# Deploy Azure resources
## Overview
1. Login to Azure using a service principal secret.
2. Create a new resource group.
3. Create a new user-assigned managed identity in the resource group.
4. Deploy resources defined in `infra/main.bicep` file to the resource group.

## Login to Azure
A service principal should be setup to let GitHub workflows login to Azure. You can create one using the following guide: [Create a service principal and assign a role to it](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal). Once the service principal ready, use the following guide to create a new client secret: [Create a new client secret](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-3-create-a-new-client-secret).

### Service principal
#### Roles
`Contributor` role should be assigned to the service principal. The `Contributor` role is required to create resources in the subscription. The `Contributor` role is assigned to the service principal using the following command:
```bash
az role assignment create --assignee <service-principal-id> --role "Contributor" --scope /subscriptions/<subscription-id>
```

Want to check the service principal's roles? Run the following command:
```bash
 az role assignment list --assignee <service-principal-id>
```

#### API permissions
Following app permissions should be assigned and the admin should grant consent:
  - `Application.ReadWrite.All`
  - `AppRoleAssignment.ReadWrite.All`



#### Store Azure credentials in the GitHub repository
The workflow logs into Azure using a [service principal secret](https://github.com/Azure/login#login-with-a-service-principal-secret). An `AZURE_CREDENTIALS` repository secret should be created. It's used by [`Azure/Login`](https://github.com/Azure/login) action to open a new session. It should be a JSON object with the following properties:

```json
{
    "clientSecret":  "******",
    "subscriptionId":  "******",
    "tenantId":  "******",
    "clientId":  "******"
}
```

# Create a user-assigned managed identity
`./infra/scripts/create-script-identity.sh` script is called to create a new user-assigned managed identity in the resource group. It is created with the `Applicatrion.ReadWrite.All` Microsoft Graph permission. This permission is required to create an application registration in the Microsoft Entra ID tenant.

```bash

You can run the script from a GitHub workflow using the following command:
```bash
chmod +x ./infra/scripts/create-script-identity.sh
./infra/scripts/create-script-identity.sh \
    --managed-identity-name ${{ env.DEPLOYMENT_SCRIPT_IDENTITY }} \
    --resource-group-name ${{ env.RESOURCE_GROUP }} \
    --tenant-id ${{ vars.AZURE_TENANT_ID }} \
    --location ${{ env.LOCATION }}
```