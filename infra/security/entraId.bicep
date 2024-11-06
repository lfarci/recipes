@description('Name of the key vault to store the client secret into.')
param keyVaultName string

@description('Name of the API to create in EntraId.')
param apiName string

@description('Name of the static site to create in EntraId.')
param siteName string

@description('Name of the managed identity to use for the deployment script.')
param managedIdentityName string = 'deployment-script-identity'

@description('The redirect URI for the application.')
param redirectUri string = 'http://localhost'

var scriptContent = loadTextContent('../scripts/create_application_registrations.sh')

@description('The user identity for the deployment script.')
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
  scope: resourceGroup()
}

@description('Create a new application in EntraId and store a secret in the Key Vault.')
resource createApplication 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'entra-id-setup'
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.63.0'
    scriptContent: scriptContent
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'KeyVaultName'
        value: keyVaultName
      }
      {
        name: 'ApiName'
        value: apiName
      }
      {
        name: 'SiteName'
        value: siteName
      }
      {
        name: 'RedirectUri'
        value: redirectUri
      }
    ]
  }
}

output apiClientId string = createApplication.properties.outputs.apiClientId
output siteClientId string = createApplication.properties.outputs.siteClientId
