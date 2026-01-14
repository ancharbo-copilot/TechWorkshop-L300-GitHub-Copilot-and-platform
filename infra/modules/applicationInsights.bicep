@description('The name of the Application Insights resource')
param name string

@description('The location for Application Insights')
param location string = resourceGroup().location

@description('The Log Analytics workspace ID')
param workspaceId string

@description('Tags to apply to the resource')
param tags object = {}

// Application Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The name of the Application Insights resource')
output name string = appInsights.name

@description('The instrumentation key')
@secure()
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string')
@secure()
output connectionString string = appInsights.properties.ConnectionString

@description('The resource ID')
output id string = appInsights.id
