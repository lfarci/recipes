@description('Application name. Application service plan is derived from this name.')
param appName string

@description('Entra ID app registration client ID.')
param entraIdClientId string

@secure()
@description('Entra ID app registration client secret name. This is used to retrieve the secret from the key vault.')
param entraIdClientSecretName string

@description('Entra ID tenant domain.')
param entraIdDomain string

@description('Entra ID instance.')
param entraIdInstance string

@secure()
@description('SQL Server instance connection string name. This is used to retrieve the secret from the key vault.')
param cosmosDbConnectionStringSecretName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The SKU of the App Service Plan. Default is F1.')
param sku string = 'F1'

@description('The Runtime stack of current web app. Default is .NET Core 8.0.')
param linuxFxVersion string = 'DOTNETCORE|8.0'

@description('Name of the key vault to store the client secret into.')
param keyVaultName string

var appServicePlanPortalName = '${appName}-plan'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanPortalName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: ['*']
      }
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource cosmosDbConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = {
  parent: keyVault
  name: cosmosDbConnectionStringSecretName
}

resource entraIdClientSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = {
  parent: keyVault
  name: entraIdClientSecretName
}

resource updateAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    KeyVaultName: keyVaultName
    AzureAd__ClientId: entraIdClientId
    AzureAd__Domain: entraIdDomain
    AzureAd__Instance: entraIdInstance
    AzureAd__TenantId: subscription().tenantId
    Api__ClientSecret: entraIdClientSecret.properties.secretUriWithVersion
  }
}

resource updateConnectionStrings 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: webApp
  name: 'connectionstrings'
  properties: {
    RecipesDocumentDatabase: {
      value: cosmosDbConnectionStringSecret.properties.secretUriWithVersion
      type: 'DocDb'
    }
  }
}

output webAppUrl string = webApp.properties.defaultHostName
