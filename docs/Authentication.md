# Authentication
The Web API is configured to use [Microsoft Identity Platform](https://learn.microsoft.com/en-us/entra/identity-platform/).

## Setup
- [Web API registration](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-01-register-app)
- [Web API configuration](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-02-prepare-api)
- [Web API usage](https://learn.microsoft.com/en-us/entra/identity-platform/web-api-tutorial-03-protect-endpoint)


## Get an access token during development
```
// Get authorization code, use this in the browser. After signing in you should get redirected to
// {redirectUri}/code={authorizationCode}

GET https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/authorize?
    client_id={clientId}
    &response_type=code
    &redirect_uri={redirectUri}
    &response_mode=query
    &scope=api://{clientId}/{scopeName}

// Request an access token using the authorization code.

POST https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded

client_id={clientId}
&scope=api://{clientId}/{scope}
&code={authorizationCode}
&session_state={clientId}
&redirect_uri={redirectUri}
&grant_type=authorization_code
&client_secret={clientSecret}
```

## Scopes
| Name               | Method | Endpoints    | Description                          |
| ------------------ | ------ | ------------ | ------------------------------------ |
|`Recipes.User.Read` | `GET`  | `Profile`    | Read the authenticated user profile. |
|`Recipes.User.Write`| `POST` | `CreateUser` | Create a new user profile.           |