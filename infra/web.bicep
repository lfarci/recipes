param appName string
param repository string

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  location: 'West Europe'
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
