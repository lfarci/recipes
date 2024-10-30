@description('Name of the key vault.')
param keyVaultName string = 'app-${uniqueString(resourceGroup().id)}-kv'

@description('Location of the key vault.')
param location string = resourceGroup().location

@description('Object ID of the deployment script used to create the service principals in EntraId. This used to set permissions to store application secrets in the key vault.')
param deploymentScriptObjectId string

@description('Object ID of the administrator. Permissions are given to this user on the secrets.')
param adminUserObjectId string

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
        objectId: deploymentScriptObjectId
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
