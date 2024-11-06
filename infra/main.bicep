param applicationName string
param environmentName string
param deploymentScriptIdentityName string
param location string = resourceGroup().location
param adminUserObjectId string
param entraIdInstance string

var fullApplicationName = '${applicationName}-${environmentName}'
var keyVaultName = 'app-${uniqueString(resourceGroup().id)}-kv'
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

module webModule 'web.bicep' = {
  name: 'webModule'
  params: {
    appName: staticSiteName
    repository: 'https://github.com/lfarci/recipes'
  }
}

var frontendAuthenticationCallback = 'https://${webModule.outputs.uri}/authentication/login-callback'

module appRegistration 'security/entraId.bicep' = {
  name: 'entra-id-setup'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    keyVaultName: keyVaultName
    apiName: apiName
    siteName: staticSiteName
    managedIdentityName: deploymentScriptIdentityName
    redirectUri: frontendAuthenticationCallback
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
    entraIdClientId: appRegistration.outputs.apiClientId
    entraIdDomain: 'lfarciava.onmicrosoft.com'
    entraIdInstance: entraIdInstance
    keyVaultName: keyVaultName
    environmentName: 'Production'
  }
}

output siteUri string = webModule.outputs.uri
output siteClientId string = appRegistration.outputs.siteClientId

output apiUri string = apiModule.outputs.uri
output apiClientId string = appRegistration.outputs.apiClientId
output tenantId string = subscription().tenantId
