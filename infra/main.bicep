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
var staticSiteName = '${fullApplicationName}-site'
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
    location: location
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
    redirectUri: 'https://localhost/authentication/login-callback'
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
    entraIdDomain: 'lfarciava.onmicrosoft.com'
    entraIdInstance: entraIdInstance
    keyVaultName: keyVaultName
    environmentName: 'Production'
  }
}

module webModule 'web.bicep' = {
  name: 'webModule'
  params: {
    appName: staticSiteName
    repository: 'https://github.com/lfarci/recipes'
  }
}
