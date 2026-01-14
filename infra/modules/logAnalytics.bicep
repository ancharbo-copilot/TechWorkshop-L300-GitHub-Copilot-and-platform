@description('The name of the Log Analytics workspace')
param name string

@description('The location for the Log Analytics workspace')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The name of the Log Analytics workspace')
output name string = logAnalytics.name

@description('The resource ID')
output id string = logAnalytics.id

@description('The workspace ID (customer ID)')
output customerId string = logAnalytics.properties.customerId
