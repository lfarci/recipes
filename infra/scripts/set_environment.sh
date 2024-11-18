#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 --environment <environment>"
    exit 1
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --environment) 
            environment="$2"
            shift 
            ;;
        *) 
            echo "Unknown parameter passed: $1"
            usage 
            ;;
    esac
    shift
done

# Check if the environment parameter is provided
if [ -z "$environment" ]; then
    echo "The --environment parameter is required."
    usage
fi

# Set the tag based on the environment
case $environment in
        'Development')
            tag='dev'
            ;;
        'Test')
            tag='tst'
            ;;
        'Production')
            tag='prd'
            ;;
        *)
            echo "Invalid environment: $environment"
            usage
            ;;
esac

# Set environment variables
echo "Setting variables for $environment environment..."

{
    echo "ENVIRONMENT_TAG=$tag"
    echo "ENVIRONMENT_NAME=$environment"
    echo "RESOURCE_GROUP=lfarci-recipes-$tag-rg"
} >> $GITHUB_ENV

# Output the environment variables
echo "ENVIRONMENT_TAG=$tag"
echo "ENVIRONMENT_NAME=$environment"
echo "RESOURCE_GROUP=lfarci-recipes-$tag-rg"