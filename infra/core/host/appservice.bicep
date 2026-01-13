param name string
param location string = resourceGroup().location
param tags object = {}

param appServicePlanId string
param runtimeName string = 'dotnetcore'
param runtimeVersion string = '6.0'

param applicationInsightsName string = ''
param appSettings object = {}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: '${runtimeName}|${runtimeVersion}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        for key in objectKeys(appSettings): {
          name: key
          value: appSettings[key]
        }
      ]
    }
    httpsOnly: true
  }
}

// Add Application Insights integration if provided
resource appServiceConfig 'Microsoft.Web/sites/config@2022-09-01' = if (!empty(applicationInsightsName)) {
  name: 'appsettings'
  parent: appService
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.principalId
output id string = appService.id
