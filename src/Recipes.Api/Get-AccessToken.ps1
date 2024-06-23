$json = dotnet user-secrets list --json;
$secrets = $json | Select-Object -Skip 1 | Select-Object -SkipLast 1 | ConvertFrom-Json

if ($secrets) {
    Write-Host "Secrets were read successfully from the project secrets storage.";
} else {
    Write-Host "Failed to read secrets. Make to set following secrets: AzureAd:ClientId, AzureAd:TenantId, Api:ClientSecret.";
}

$redirectUri="$env:RECIPES_API_REDIRECT_URI";

$clientId = $secrets."AzureAd:ClientId";
$clientSecret = $secrets."Api:ClientSecret";
$tenantId = $secrets."AzureAd:TenantId";

if ([string]::IsNullOrEmpty($redirectUri)) {
    $redirectUri = "http://localhost";
}

if ([string]::IsNullOrEmpty($clientId)) {
    Write-Host "Set AzureAd:ClientId secret in project secrets storage.";
    return;
}

if ([string]::IsNullOrEmpty($clientSecret)) {
    Write-Host "Set Api:ClientSecret secret in project secrets storage.";
    return;
}

if ([string]::IsNullOrEmpty($tenantId)) {
    Write-Host "Set AzureAd:TenantId secret in project secrets storage.";
    return;
}

$scopes="api://$clientId/Recipes.User.Read api://$clientId/Recipes.User.Write"
$tokenUrl="https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$authorizeEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?
    client_id=$clientId
    &response_type=code
    &redirect_uri=$redirectUri
    &response_mode=query
    &scope=$scopes"

Write-Host "Sign in and get your authorization code using this URI: $authorizeEndpoint";
do {
    $code = Read-Host "Enter the authorization code"
} while ([string]::IsNullOrEmpty($code))

$requestBody = @{
    client_id = $clientId
    scope = $scopes
    code = $code
    redirect_uri = $redirectUri
    grant_type = "authorization_code"
    client_secret = $clientSecret
}

$requestBodyString = ($requestBody.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&";

$response = Invoke-RestMethod -Method POST -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $requestBodyString

Write-Host "Response: $response";

$accessToken = $response.access_token;

Write-Host "Access Token: $accessToken";