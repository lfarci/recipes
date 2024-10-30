param applicationName string
param environmentName string
param deploymentScriptIdentityName string
param location string = resourceGroup().location
param adminUserObjectId string
param entraIdInstance string

var fullApplicationName = '${applicationName}-${environmentName}'
var keyVaultName = 'app-${uniqueString(resourceGroup().id)}-kv'
var applicationRegistrationName = '${fullApplicationName}-app'
var apiName = '${fullApplicationName}-api'
var databaseAccountName = '${fullApplicationName}-cosmos-db'


@description('The user identity for the deployment script.')
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: deploymentScriptIdentityName
  scope: resourceGroup()
}

module keyVaultModule 'security/keyVault.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: keyVaultName
    adminUserObjectId: adminUserObjectId
    deploymentScriptObjectId: scriptIdentity.properties.principalId
  }
}

module appRegistration 'security/entraId.bicep' = {
  name: 'entra-id-setup'
  dependsOn: [
    keyVaultModule
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
    keyVaultModule
  ]
  params: {
    accountName: databaseAccountName
    location: location
    keyVaultName: keyVaultName
  }
}

module apiModule 'api/webapp.bicep' = {
  name: 'api'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    appName: apiName
    entraIdClientId: appRegistration.outputs.applicationClientId
    entraIdClientSecretName: 'Api--ClientSecret'
    entraIdDomain: 'lfarciava.onmicrosoft.com'
    entraIdInstance: entraIdInstance
    cosmosDbConnectionStringSecretName: 'RecipesDocumentDatabase'
    keyVaultName: keyVaultName
  }
}

// module webModule 'web.bicep' = {
//   name: 'webModule'
//   params: {
//     // Add parameters required by web.bicep
//   }
// }
