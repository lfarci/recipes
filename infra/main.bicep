param applicationName string
param environmentName string
param deploymentScriptIdentityName string
param location string = resourceGroup().location
param adminUserObjectId string
param entraIdInstance string

var fullApplicationName = '${applicationName}-${environmentName}'
var keyVaultName = '${uniqueString(resourceGroup().id)}-kv'
var applicationRegistrationName = '${fullApplicationName}-app'
var apiName = '${fullApplicationName}-api'
var databaseAccountName = '${fullApplicationName}-cosmos-db'


@description('The user identity for the deployment script.')
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: deploymentScriptIdentityName
  scope: resourceGroup()
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
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
        objectId: adminUserObjectId
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
  dependsOn: [
    keyVault
  ]
  params: {
    keyVaultName: keyVaultName
    applicationName: applicationRegistrationName
    managedIdentityName: deploymentScriptIdentityName
  }
}

module databaseModule 'database.bicep' = {
  name: 'database'
  dependsOn: [
    keyVault
  ]
  params: {
    accountName: databaseAccountName
    location: location
    keyVaultName: keyVaultName
  }
}

module apiModule 'api.bicep' = {
  name: 'api'
  dependsOn: [
    keyVault
  ]
  params: {
    appName: apiName
    entraIdClientId: appRegistration.outputs.applicationClientId
    entraIdClientSecretName: appRegistration.outputs.clientSecretName
    entraIdDomain: 'lfarciava.onmicrosoft.com'
    entraIdInstance: entraIdInstance
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
