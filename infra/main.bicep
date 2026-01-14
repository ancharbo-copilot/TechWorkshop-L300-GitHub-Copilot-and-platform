targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the application')
param applicationName string = 'zavastore'

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Tags to apply to all resources')
param tags object = {}

// Load abbreviations for resource naming
var abbrs = loadJsonContent('./abbreviations.json')

// Generate unique resource names
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${abbrs.resourceGroup}-${applicationName}-${environmentName}-${location}'
  location: location
  tags: union(tags, { 'azd-env-name': environmentName })
}

// Log Analytics Workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'log-analytics-deployment'
  scope: rg
  params: {
    name: '${abbrs.logAnalyticsWorkspace}-${applicationName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights './modules/applicationInsights.bicep' = {
  name: 'app-insights-deployment'
  scope: rg
  params: {
    name: '${abbrs.applicationInsights}-${applicationName}-${resourceToken}'
    location: location
    workspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// Container Registry
module containerRegistry './modules/containerRegistry.bicep' = {
  name: 'container-registry-deployment'
  scope: rg
  params: {
    name: '${abbrs.containerRegistry}${applicationName}${resourceToken}'
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'app-service-plan-deployment'
  scope: rg
  params: {
    name: '${abbrs.appServicePlan}-${applicationName}-${resourceToken}'
    location: location
    sku: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
    tags: tags
  }
}

// Web App for Containers
module webApp './modules/webApp.bicep' = {
  name: 'web-app-deployment'
  scope: rg
  params: {
    name: '${abbrs.appService}-${applicationName}-${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerImageName: 'zavastore:latest'
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    tags: tags
  }
}

// Role Assignment: Grant Web App AcrPull on Container Registry
module acrPullRole './modules/roleAssignment.bicep' = {
  name: 'acr-pull-role-assignment'
  scope: rg
  params: {
    principalId: webApp.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalType: 'ServicePrincipal'
  }
}

// AI Hub (Microsoft Foundry)
module aiHub './modules/foundry.bicep' = {
  name: 'ai-hub-deployment'
  scope: rg
  params: {
    name: '${abbrs.aiHub}-${applicationName}-${resourceToken}'
    location: location
    friendlyName: 'Zava AI Hub - ${environmentName}'
    description: 'AI Hub for ZavaStorefront with GPT-4 and Phi model access'
    tags: tags
  }
}

// Outputs for azd and deployment
@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = rg.name

@description('The location of the resources')
output AZURE_LOCATION string = location

@description('The name of the container registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The login server of the container registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The name of the web app')
output AZURE_WEB_APP_NAME string = webApp.outputs.name

@description('The default hostname of the web app')
output SERVICE_WEB_URI string = 'https://${webApp.outputs.defaultHostname}'

@description('The Application Insights connection string')
@secure()
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString

@description('The AI Hub name')
output AZURE_AI_HUB_NAME string = aiHub.outputs.name
