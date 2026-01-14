@description('The name of the web app')
param name string

@description('The location for the web app')
param location string = resourceGroup().location

@description('The App Service Plan ID')
param appServicePlanId string

@description('The container registry login server')
param containerRegistryLoginServer string

@description('The container image name')
param containerImageName string = 'zavastore:latest'

@description('The Application Insights connection string')
@secure()
param appInsightsConnectionString string = ''

@description('The Application Insights instrumentation key')
@secure()
param appInsightsInstrumentationKey string = ''

@description('Tags to apply to the resource')
param tags object = {}

// Web App for Containers
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned' // Enable managed identity for ACR pull
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true // Security best practice: enforce HTTPS
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/${containerImageName}'
      acrUseManagedIdentityCreds: true // Use managed identity for ACR
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
    }
  }
}

@description('The name of the web app')
output name string = webApp.name

@description('The default hostname of the web app')
output defaultHostname string = webApp.properties.defaultHostName

@description('The resource ID of the web app')
output id string = webApp.id

@description('The principal ID of the web app managed identity')
output principalId string = webApp.identity.principalId
