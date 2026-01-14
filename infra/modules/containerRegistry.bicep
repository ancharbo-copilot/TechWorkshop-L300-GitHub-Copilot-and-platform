@description('The name of the container registry')
param name string

@description('The location for the container registry')
param location string = resourceGroup().location

@description('The SKU for the container registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

// Container Registry resource
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Security best practice: disable admin user
    anonymousPullEnabled: false // Security best practice: disable anonymous pull
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

@description('The name of the container registry')
output name string = containerRegistry.name

@description('The login server of the container registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The resource ID of the container registry')
output id string = containerRegistry.id
