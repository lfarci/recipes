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