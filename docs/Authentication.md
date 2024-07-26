# Authentication
## Web API
The Web API is configured to use [Microsoft Identity Platform](https://learn.microsoft.com/en-us/entra/identity-platform/). 

Following guides were used during the setup.
- [Web API registration](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-01-register-app)
- [Web API configuration](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-02-prepare-api)
- [Web API usage](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-03-protect-endpoint)

## Web application
The guide [Secure an ASP.NET Core Blazor WebAssembly standalone app with Microsoft Entra ID](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/webassembly/standalone-with-microsoft-entra-id?view=aspnetcore-8.0) was used to setup the application.

### Scopes
| Name               | Method | Endpoints    | Description                          |
| ------------------ | ------ | ------------ | ------------------------------------ |
|`Recipes.User.Read` | `GET`  | `Profile`    | Read the authenticated user profile. |
|`Recipes.User.Write`| `POST` | `CreateUser` | Create a new user profile.           |

# Read user details using Microsoft Graph

# Development
## Get an access token
A PowerShell script has been created (`src/Recipes.Api/Get-AccessToken.ps1`). It can be used when working on the backend service independently.



