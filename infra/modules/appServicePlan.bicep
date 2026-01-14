@description('The name of the App Service Plan')
param name string

@description('The location for the App Service Plan')
param location string = resourceGroup().location

@description('The SKU for the App Service Plan')
param sku object = {
  name: 'B1'
  tier: 'Basic'
  capacity: 1
}

@description('Tags to apply to the resource')
param tags object = {}

// App Service Plan resource (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

@description('The name of the App Service Plan')
output name string = appServicePlan.name

@description('The resource ID of the App Service Plan')
output id string = appServicePlan.id
