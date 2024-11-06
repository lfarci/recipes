@description('The name of the static web app.')
param appName string

@description('The URL of the repository to deploy.')
param repository string

@description('The location of the resources.')
param location string = resourceGroup().location

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  location: location
  name: appName
  properties: {
    allowConfigFileUpdates: true
    branch: 'master'
    enterpriseGradeCdnStatus: 'Disabled'
    provider: 'GitHub'
    repositoryUrl: repository
    stagingEnvironmentPolicy: 'Enabled'
  }
  sku: {
    name: 'Free'
    tier: 'Free'
  }
}

resource staticWebAppBasicAuth 'Microsoft.Web/staticSites/basicAuth@2023-12-01' = {
  parent: staticWebApp
  name: 'default'
  properties: {
    applicableEnvironmentsMode: 'SpecifiedEnvironments'
  }
}

output uri string = staticWebApp.properties.defaultHostname
