#!/bin/bash

resourceGroupName="lfarci-recipes"

az group create --name $resourceGroupName --location "westeurope" &&
az deployment group create --resource-group $resourceGroupName --template-file database.bicep --parameters database.dev.bicepparam &&
az deployment group create --resource-group $resourceGroupName --template-file api.bicep --parameters api.dev.bicepparam &&
az deployment group create --resource-group $resourceGroupName --template-file web.bicep --parameters web.dev.bicepparam


