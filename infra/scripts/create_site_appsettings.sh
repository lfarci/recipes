while [[ "$#" -gt 0 ]]; do
    case $1 in
        --uri) uri="$2"; shift ;;
        --api-uri) api_uri="$2"; shift ;;
        --tenant-id) tenant_id="$2"; shift ;;
        --id) id="$2"; shift ;;
        --api-id) api_id="$2"; shift ;;
        --output) output="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$uri" ] || [ -z "$api_uri" ] || [ -z "$tenant_id" ] || [ -z "$id" ] || [ -z "$api_id" ] || [ -z "$output" ]; then
    echo "All parameters --uri, --api-uri, --tenant-id, --id, --api-id, and --output are required."
    exit 1
fi

echo "Creating appsettings.json with the following values:"
echo "BaseAddress: $uri"
echo "RecipesApiAddress: $api_uri"
echo "AzureAd:Authority: https://login.microsoftonline.com/$tenant_id"
echo "AzureAd:ClientId: $id"
echo "AzureAd:DefaultAccessTokenScopes: api://$api_id/.default"

if [ -f "$output" ]; then
    echo "File $output already exists. Overwriting..."
else
    echo "Creating file $output..."
fi

cat > $output <<EOL
{
  "BaseAddress": "$uri",
  "RecipesApiAddress": "$api_uri",
  "AzureAd": {
    "Authority": "https://login.microsoftonline.com/$tenant_id",
    "ClientId": "$id",
    "ValidateAuthority": true,
    "DefaultAccessTokenScopes": [
      "api://$api_id/.default"
    ]
  }
}
EOL
