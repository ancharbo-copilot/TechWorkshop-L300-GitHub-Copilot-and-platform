using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westus3')
param applicationName = 'zavastore'
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param tags = {
  'app-name': 'ZavaStorefront'
  'environment': environmentName
  'managed-by': 'azd'
}
