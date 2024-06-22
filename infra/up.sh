#!/bin/bash

resourceGroupName="lfarci-recipes"

az group create --name $resourceGroupName --location "westeurope" &&
az deployment group create --resource-group $resourceGroupName --template-file api.bicep --parameters api.dev.bicepparam