# Azure Deployment Quick Start

This document provides quick commands to deploy the ZavaStorefront application to Azure.

## Prerequisites Check

```bash
# Check Azure CLI
az --version

# Check Azure Developer CLI
azd version

# Login to Azure
az login
azd auth login

# Set subscription (if you have multiple)
az account set --subscription "<subscription-id>"
```

## Quick Deploy (One Command)

```bash
# From project root directory
azd up
```

This will:
1. Prompt for environment name (e.g., `dev`)
2. Prompt for Azure location (use `westus3` for Foundry support)
3. Provision all infrastructure
4. Build container image in ACR
5. Deploy application to App Service
6. Display application URL

## Step-by-Step Deploy

```bash
# 1. Initialize (first time only)
azd init

# 2. Set environment variables
azd env set AZURE_ENV_NAME dev
azd env set AZURE_LOCATION westus3

# 3. Preview infrastructure changes
azd provision --preview

# 4. Provision infrastructure
azd provision

# 5. Deploy application
azd deploy

# 6. Get application URL
azd env get-values | grep SERVICE_WEB_URI
```

## Build Container Manually

```bash
# Get ACR name
ACR_NAME=$(azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME | cut -d'=' -f2 | tr -d '"')

# Build and push image (cloud-based, no local Docker)
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file ./src/Dockerfile \
  ./src
```

## View Application

```bash
# Get the application URL
APP_URL=$(azd env get-values | grep SERVICE_WEB_URI | cut -d'=' -f2 | tr -d '"')
echo "Application: $APP_URL"

# Test the application
curl -I $APP_URL
```

## Monitor Application

```bash
# Open Application Insights dashboard
azd monitor

# Stream logs
WEBAPP=$(azd env get-values | grep AZURE_WEB_APP_NAME | cut -d'=' -f2 | tr -d '"')
RG=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')
az webapp log tail --name $WEBAPP --resource-group $RG
```

## Cleanup

```bash
# Delete all resources
azd down

# Delete without confirmation
azd down --force --purge
```

## Troubleshooting

### If deployment fails:

```bash
# View detailed logs
azd provision --debug

# Check Azure activity log
az monitor activity-log list --resource-group <rg-name> --max-events 50
```

### If container doesn't start:

```bash
# Check Web App logs
az webapp log tail --name $WEBAPP --resource-group $RG

# Check container settings
az webapp config show --name $WEBAPP --resource-group $RG
```

### Reset environment:

```bash
# Delete resources and start over
azd down --force
azd up
```

## Costs

Expected monthly cost for dev environment: **~$22-25** (excluding AI model usage)

To minimize costs:
- Use `azd down` when not actively developing
- Review costs in Azure Portal > Cost Management
