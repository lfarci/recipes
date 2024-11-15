#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 --uri <uri> --api-uri <api-uri> --tenant-id <tenant-id> --id <id> --api-id <api-id> --template <template_file> --output <output>"
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
    --template) template_file="$2"; shift ;;
    --output) output_file="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Validate required parameters
if [ -z "$uri" ] || [ -z "$api_uri" ] || [ -z "$tenant_id" ] || [ -z "$client_id" ] || [ -z "$api_id" ] || [ -z "$template_file" ] || [ -z "$output_file" ]; then
  echo "All parameters --uri, --api-uri, --tenant-id, --id, --api-id, --template, and --output are required."
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

# Replace placeholders in the template file
sed -e "s|{{SITE_URI}}|$uri|g" \
    -e "s|{{API_URI}}|$api_uri|g" \
    -e "s|{{TENANT_ID}}|$tenant_id|g" \
    -e "s|{{CLIENT_ID}}|$client_id|g" \
    -e "s|{{API_ID}}|$api_id|g" \
    $template_file > $output_file

echo "Configuration file created successfully at $output_file."