targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Optional parameters
@description('Name of the resource group')
param resourceGroupName string = ''

// Variables
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Monitor Application Insights
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
  }
}

// Container Registry
module containerRegistry './core/host/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
  }
}

// App Service Plan
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.webServerFarms}${resourceToken}'
    sku: {
      name: 'B1'
      tier: 'Basic'
    }
    kind: 'linux'
    reserved: true
  }
}

// Web App
module web './core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    name: '${abbrs.webSitesAppService}web-${resourceToken}'
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'dotnetcore'
    runtimeVersion: '6.0'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appSettings: {
      DOCKER_REGISTRY_SERVER_URL: containerRegistry.outputs.loginServer
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    }
  }
}

// Azure AI Foundry (Cognitive Services)
module aiFoundry './core/ai/cognitiveservices.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    location: location
    tags: tags
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    kind: 'CognitiveServices'
    sku: {
      name: 'S0'
    }
  }
}

// Role assignments for the web app to pull from ACR
module webAcrPullRole './core/security/role.bicep' = {
  name: 'web-acr-pull-role'
  scope: rg
  params: {
    principalId: web.outputs.identityPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

output WEB_APP_NAME string = web.outputs.name
output WEB_APP_URI string = web.outputs.uri
output WEB_APP_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName

output AZURE_AI_FOUNDRY_NAME string = aiFoundry.outputs.name
output AZURE_AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
