# App settings
```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "Domain": "{tenantName}.onmicrosoft.com",
    "TenantId": "{tenantId}",
    "ClientId": "{clientId}",
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

# Secrets
During development secrets are stored using the [Secret Manager](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-8.0&tabs=windows).

```
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:Recipes.Database"
dotnet user-secrets set "AzureAd:Domain" "{tenantName}.onmicrosoft.com"
dotnet user-secrets set "AzureAd:TenantId" "{tenantId}"
dotnet user-secrets set "AzureAd:ClientId" "{ClientId}"
```