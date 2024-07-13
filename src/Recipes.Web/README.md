# About
The current project was setup by following this guide: [Secure an ASP.NET Core Blazor WebAssembly standalone app with Microsoft Entra ID](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/webassembly/standalone-with-microsoft-entra-id?view=aspnetcore-8.0)'.

# Secrets
Secrets should be encoded in a local development appsettings.json file. This file should be added to the .gitignore file to prevent it from being checked into source control. The appsettings.json file should be structured as follows:

```json
{
  "AzureAd": {
	"Authority": "https://login.microsoftonline.com/{TENANT ID}",
	"ClientId": "{CLIENT ID}",
	"ValidateAuthority": true
  }
}
```

# Deployment
[Deploy a Blazor app on Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/deploy-blazor)