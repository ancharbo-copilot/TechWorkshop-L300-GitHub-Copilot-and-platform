# Azure Infrastructure Deployment Guide

## Overview
This project uses Azure Developer CLI (azd) and Bicep to provision Azure infrastructure for the ZavaStorefront web application.

## Architecture

### Azure Resources
The infrastructure includes the following Azure resources:

1. **Resource Group** - Contains all resources in westus3
2. **Azure Container Registry (ACR)** - Stores Docker container images
3. **App Service Plan (Linux)** - Hosts the web application (Basic B1 SKU for dev)
4. **App Service (Linux Web App)** - Runs the ZavaStorefront application
5. **Application Insights** - Application monitoring and telemetry
6. **Log Analytics Workspace** - Logs and analytics backend
7. **Azure Cognitive Services** - AI Foundry for GPT-4 and Phi models

### Security
- App Service uses **System Assigned Managed Identity**
- Managed identity is granted **AcrPull** role on Container Registry
- No passwords or access keys required for container pulls
- HTTPS-only enforcement on App Service

## Prerequisites

1. **Azure Developer CLI (azd)** - Already installed
2. **Azure CLI (az)** - Already installed
3. **Docker** - Available in the dev container
4. **Azure Subscription** - You need access to an Azure subscription
5. **.NET 6 SDK** - Already installed

## Deployment Steps

### 1. Authenticate with Azure

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription <subscription-id>

# Authenticate azd
azd auth login
```

### 2. Initialize AZD Environment

```bash
# Initialize azd with your environment name
azd init

# Or provision directly with:
azd up
```

### 3. Deploy Infrastructure

The `azd up` command will:
- Provision all Azure resources defined in Bicep templates
- Build the Docker container image
- Push the image to Azure Container Registry
- Deploy the container to App Service

```bash
azd up
```

You'll be prompted for:
- **Environment name** (e.g., "dev", "staging")
- **Azure subscription**
- **Location** (use westus3 for AI Foundry availability)

### 4. Verify Deployment

After deployment completes, azd will output:
- Resource group name
- Web app URL
- Container registry name
- Application Insights connection string

Access your application at the web app URL.

## Infrastructure Details

### Resource Naming Convention
Resources use Azure naming abbreviations:
- `rg-` - Resource Group
- `cr` - Container Registry
- `plan-` - App Service Plan
- `app-` - App Service
- `appi-` - Application Insights
- `log-` - Log Analytics Workspace
- `cog-` - Cognitive Services

### Container Deployment Workflow

1. Docker image is built from the Dockerfile
2. Image is pushed to Azure Container Registry
3. App Service pulls the image using its managed identity
4. No credentials needed due to RBAC configuration

### Application Settings

The App Service is configured with:
- `DOCKER_REGISTRY_SERVER_URL` - ACR login server URL
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - For telemetry
- `WEBSITES_ENABLE_APP_SERVICE_STORAGE` - Disabled for container apps

## CI/CD Integration

To set up GitHub Actions for automated deployment:

```bash
azd pipeline config
```

This will:
- Create a service principal
- Configure GitHub secrets
- Set up GitHub Actions workflow

## Monitoring

### Application Insights
- Navigate to Azure Portal → Application Insights
- View live metrics, failures, and performance data
- Query logs using KQL (Kusto Query Language)

### Container Logs
```bash
# View container logs
az webapp log tail --name <app-name> --resource-group <rg-name>
```

## AI Foundry Models

The deployment includes Azure Cognitive Services with:
- **GPT-4** (OpenAI format) - 10 capacity units
- **Phi-3** (latest version) - 10 capacity units

Access the models via the endpoint: `AZURE_AI_FOUNDRY_ENDPOINT`

## Cleanup

To delete all Azure resources:

```bash
azd down
```

This removes:
- Resource group and all contained resources
- azd environment configuration

## Cost Optimization

Current configuration uses development-tier SKUs:
- **App Service Plan**: Basic B1 (~$13/month)
- **Container Registry**: Basic (~$5/month)
- **Application Insights**: Pay-as-you-go (free tier available)
- **Cognitive Services**: S0 Standard (usage-based pricing)

## Troubleshooting

### Container Pull Issues
If the app service can't pull from ACR:
```bash
# Verify role assignment
az role assignment list --assignee <app-identity-id> --scope <acr-id>

# Ensure managed identity is enabled
az webapp identity show --name <app-name> --resource-group <rg-name>
```

### Build Failures
```bash
# View azd logs
azd deploy --debug

# Manually build and push
docker build -t myapp:latest -f Dockerfile ./src
az acr build --registry <acr-name> --image myapp:latest -f Dockerfile ./src
```

### Application Errors
```bash
# Stream live logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Check Application Insights for exceptions
# Azure Portal → Application Insights → Failures
```

## Additional Commands

```bash
# List all provisioned resources
azd show

# View environment variables
azd env get-values

# Update infrastructure only (no code deploy)
azd provision

# Deploy code only (infrastructure already exists)
azd deploy
```

## Support

For issues related to:
- **Azure Developer CLI**: https://github.com/Azure/azure-dev
- **Bicep**: https://github.com/Azure/bicep
- **Azure App Service**: https://docs.microsoft.com/azure/app-service
