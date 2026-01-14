@description('The name of the AI Hub (Foundry) resource')
param name string

@description('The location for the AI Hub')
param location string = resourceGroup().location

@description('The friendly name for the AI Hub')
param friendlyName string = 'Zava AI Hub'

@description('The description for the AI Hub')
param description string = 'AI Hub for ZavaStorefront with GPT-4 and Phi access'

@description('Tags to apply to the resource')
param tags object = {}

// AI Hub (Microsoft Foundry) resource
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: friendlyName
    description: description
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

@description('The name of the AI Hub')
output name string = aiHub.name

@description('The resource ID of the AI Hub')
output id string = aiHub.id

@description('The workspace ID')
output workspaceId string = aiHub.properties.workspaceId

@description('The principal ID of the managed identity')
output principalId string = aiHub.identity.principalId
