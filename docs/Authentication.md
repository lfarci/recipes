# Authentication
The Web API is configured to use [Microsoft Identity Platform](https://learn.microsoft.com/en-us/entra/identity-platform/).

## Setup
- [Web API registration](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-01-register-app)
- [Web API configuration](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-02-prepare-api)
- [Web API usage](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-03-protect-endpoint)


## Get an access token during development
A PowerShell script has been created (`src/Recipes.Api/Get-AccessToken.ps1`). It can be used when working on the backend service independently.

## Scopes
| Name               | Method | Endpoints    | Description                          |
| ------------------ | ------ | ------------ | ------------------------------------ |
|`Recipes.User.Read` | `GET`  | `Profile`    | Read the authenticated user profile. |
|`Recipes.User.Write`| `POST` | `CreateUser` | Create a new user profile.           |