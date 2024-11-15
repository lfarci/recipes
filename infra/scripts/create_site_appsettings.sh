#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 --uri <uri> --api-uri <api-uri> --tenant-id <tenant-id> --id <id> --api-id <api-id> --output <output>"
  exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --uri) uri="$2"; shift ;;
    --api-uri) api_uri="$2"; shift ;;
    --tenant-id) tenant_id="$2"; shift ;;
    --id) client_id="$2"; shift ;;
    --api-id) api_id="$2"; shift ;;
    --output) output_file="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Validate required parameters
if [ -z "$uri" ] || [ -z "$api_uri" ] || [ -z "$tenant_id" ] || [ -z "$client_id" ] || [ -z "$api_id" ] || [ -z "$output_file" ]; then
  echo "All parameters --uri, --api-uri, --tenant-id, --id, --api-id, and --output are required."
  usage
fi

# Display the values being used
echo "Creating appsettings.json with the following values:"
echo "BaseAddress: $uri"
echo "RecipesApiAddress: $api_uri"
echo "AzureAd:Authority: https://login.microsoftonline.com/$tenant_id"
echo "AzureAd:ClientId: $client_id"
echo "AzureAd:DefaultAccessTokenScopes: api://$api_id/.default"

# Check if the output file already exists
if [ -f "$output_file" ]; then
  echo "File $output_file already exists. Overwriting..."
else
  echo "Creating file $output_file..."
fi

# Create the JSON configuration file using jq
jq -n \
  --arg uri "$uri" \
  --arg api_uri "$api_uri" \
  --arg tenant_id "$tenant_id" \
  --arg client_id "$client_id" \
  --arg api_id "$api_id" \
  '{
  BaseAddress: ("https://" + $uri),
  RecipesApiAddress: ("https://" + $api_uri),
  AzureAd: {
    Authority: ("https://login.microsoftonline.com/" + $tenant_id),
    ClientId: $client_id,
    ValidateAuthority: true,
    DefaultAccessTokenScopes: [
      ("api://" + $api_id + "/access_as_user"),
      "User.Read",
      "User.ReadBasic.All"
    ]
  }
  }' > "$output_file"

# Check if jq command was successful
if [ $? -ne 0 ]; then
  echo "Failed to create JSON configuration file."
  exit 1
fi

# Convert line endings to CRLF using sed
sed -i 's/$/\r/' "$output_file"

# Ensure the file is saved with UTF-8 encoding without BOM
iconv -f utf-8 -t utf-8 "$output_file" -o "$output_file"

echo "Configuration file created successfully at $output_file."