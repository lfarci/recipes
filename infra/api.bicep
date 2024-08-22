@description('Application name. Application service plan is derived from this name.')
param appName string

@description('Entra ID app registration client ID.')
param entraIdClientId string

@description('Entra ID tenant domain.')
param entraIdDomain string

@description('Entra ID instance.')
param entraIdInstance string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The SKU of the App Service Plan. Default is F1.')
param sku string = 'F1'

@description('The Runtime stack of current web app. Default is .NET Core 8.0.')
param linuxFxVersion string = 'DOTNETCORE|8.0'

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
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: ['*']
      }
      appSettings: [
        {
          name: 'AzureAd:ClientId'
          value: entraIdClientId
        }
        {
          name: 'AzureAd:Domain'
          value: entraIdDomain
        }
        {
          name: 'AzureAd:Instance'
          value: entraIdInstance
        }
        {
          name: 'AzureAd:TenantId'
          value: subscription().tenantId
        }
      ]
    }
  }
}

output webAppUrl string = webApp.properties.defaultHostName
