// var entraIdInstance = 'https://login.microsoftonline.com/'

// This is the application ID of the service principal, the registration could be created automatically
// var entraIdApplicationId = '92eed23b-512e-4052-ba33-0baeca5b8211'

var keyVaultName = 'lfarci-recipes-dev-3-kv'
var clientName = 'lfarci-recipes-app-dev'
var apiName = 'lfarci-recipes-dev-api'
var managedIdentityName = 'script-identity'

var databaseAccountName = 'lfarci-recipes-cosmos-db-dev-2'
var databaseLocation = 'Germany West Central'

var userObjectId = '84ea8042-abd6-43d4-b663-a7edc74074c9' // logan.farci@avanade.com

@description('The user identity for the deployment script.')
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
  scope: resourceGroup()
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: scriptIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: userObjectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
        }
      }
    ]
  }
}

module appRegistration 'appRegistration.bicep' = {
  name: 'appRegistration'
  params: {
    keyVaultName: keyVaultName
    applicationName: clientName
    managedIdentityName: managedIdentityName
  }
}

module databaseModule 'database.bicep' = {
  name: 'database'
  params: {
    accountName: databaseAccountName
    location: databaseLocation
    keyVaultName: keyVaultName
  }
}

module apiModule 'api.bicep' = {
  name: 'api'
  params: {
    appName: apiName
    entraIdClientId: appRegistration.outputs.applicationClientId
    entraIdClientSecretName: appRegistration.outputs.clientSecretName
    entraIdDomain: 'lfarciava.onmicrosoft.com'
    entraIdInstance: 'https://login.microsoftonline.com/'
    cosmosDbConnectionStringSecretName: 'CosmosDBConnectionString'
    keyVaultName: keyVaultName
  }
}

// module webModule 'web.bicep' = {
//   name: 'webModule'
//   params: {
//     // Add parameters required by web.bicep
//   }
// }
