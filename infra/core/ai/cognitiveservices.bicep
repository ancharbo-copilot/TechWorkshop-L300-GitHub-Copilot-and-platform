param name string
param location string = resourceGroup().location
param tags object = {}

param kind string = 'CognitiveServices'
param sku object = {
  name: 'S0'
}

param deployments array = [
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'phi-3'
    model: {
      format: 'OpenAI'
      name: 'phi-3'
      version: '3.5-mini-4k-instruct'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: cognitiveServices
  name: deployment.name
  sku: deployment.sku
  properties: {
    model: deployment.model
  }
}]

output endpoint string = cognitiveServices.properties.endpoint
output name string = cognitiveServices.name
output id string = cognitiveServices.id
