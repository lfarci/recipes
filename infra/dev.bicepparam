using 'main.bicep'

param applicationName = 'lfarci-recipes'
param environmentName = 'dev'
param deploymentScriptIdentityName = 'script-identity'
param location = 'Germany West Central'
param adminUserObjectId = '84ea8042-abd6-43d4-b663-a7edc74074c9' // logan.farci@avanade.com
param entraIdInstance = 'https://login.microsoftonline.com/'