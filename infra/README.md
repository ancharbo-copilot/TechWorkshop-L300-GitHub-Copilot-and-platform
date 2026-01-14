# ZavaStorefront Infrastructure Deployment

This directory contains the Infrastructure as Code (IaC) for deploying the ZavaStorefront application to Azure using Bicep and Azure Developer CLI (azd).

## 🏗️ Architecture

The infrastructure provisions the following Azure resources:

- **Resource Group**: Container for all resources
- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan (Linux)**: B1 SKU for cost-effective hosting
- **Web App for Containers**: Hosts the containerized .NET application
- **Application Insights**: Application monitoring and diagnostics
- **Log Analytics Workspace**: Backend for Application Insights
- **Microsoft Foundry (AI Hub)**: GPT-4 and Phi model access
- **Role Assignments**: Managed identity with AcrPull for passwordless ACR access

## 🔐 Security Features

✅ **No passwords or secrets required**  
✅ **Managed Identity authentication** for ACR pull  
✅ **HTTPS enforced** on Web App  
✅ **Admin user disabled** on Container Registry  
✅ **Anonymous pull disabled** on ACR  
✅ **Latest API versions** for all resources  
✅ **Secure parameter handling** with `@secure()` decorator  

## 📁 Project Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── main.bicepparam                 # Parameters file
├── abbreviations.json              # Resource naming conventions
└── modules/
    ├── containerRegistry.bicep     # Azure Container Registry
    ├── appServicePlan.bicep        # App Service Plan (Linux)
    ├── webApp.bicep                # Web App for Containers
    ├── applicationInsights.bicep   # Application Insights
    ├── logAnalytics.bicep          # Log Analytics Workspace
    ├── foundry.bicep               # Microsoft Foundry (AI Hub)
    └── roleAssignment.bicep        # RBAC role assignments
```

## 🚀 Prerequisites

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   az --version
   ```

2. **Azure Developer CLI (azd)**
   ```bash
   azd version
   ```

3. **Azure Subscription** with:
   - Contributor access
   - Quota for Microsoft Foundry in `westus3`
   - GPT-4 and Phi model availability in `westus3`

4. **Authentication**
   ```bash
   az login
   azd auth login
   ```

## 📋 Deployment Steps

### Option 1: Full Deployment (Recommended)

Deploy everything with a single command:

```bash
# Initialize the environment (first time only)
azd init

# Set environment name and location
azd env set AZURE_ENV_NAME dev
azd env set AZURE_LOCATION westus3

# Preview what will be deployed
azd provision --preview

# Provision infrastructure and deploy application
azd up
```

### Option 2: Step-by-Step Deployment

If you prefer more control:

```bash
# 1. Provision infrastructure only
azd provision --preview  # Review changes first
azd provision            # Create resources

# 2. Build and deploy application
azd deploy
```

### Option 3: Manual Container Build

Build and push the container image manually:

```bash
# Get the ACR name from environment
ACR_NAME=$(azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME | cut -d'=' -f2 | tr -d '"')

# Build in Azure (no local Docker needed)
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file ./src/Dockerfile \
  ./src

# Web App will automatically pull the new image
```

## 🔍 Validation

After deployment, verify the resources:

```bash
# Get the application URL
azd env get-values | grep SERVICE_WEB_URI

# Get the resource group name
azd env get-values | grep AZURE_RESOURCE_GROUP

# Test the application
curl -I $(azd env get-values | grep SERVICE_WEB_URI | cut -d'=' -f2 | tr -d '"')
```

View in Azure Portal:
```bash
RESOURCE_GROUP=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')
echo "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
```

## 📊 Monitoring

Access Application Insights:

```bash
# Open Application Insights in portal
azd monitor

# Stream logs from Web App
az webapp log tail \
  --name $(azd env get-values | grep AZURE_WEB_APP_NAME | cut -d'=' -f2 | tr -d '"') \
  --resource-group $(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')
```

## 🛠️ Troubleshooting

### Container not pulling from ACR

Check managed identity and role assignment:

```bash
WEBAPP_NAME=$(azd env get-values | grep AZURE_WEB_APP_NAME | cut -d'=' -f2 | tr -d '"')
RG=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')

# Verify managed identity is enabled
az webapp identity show --name $WEBAPP_NAME --resource-group $RG

# Check if acrUseManagedIdentityCreds is true
az webapp config show --name $WEBAPP_NAME --resource-group $RG --query "acrUseManagedIdentityCreds"
```

### Image build fails

Ensure you're in the correct directory:

```bash
# Build should be run from project root
az acr build --registry $ACR_NAME --image zavastore:latest --file ./src/Dockerfile ./src
```

### Microsoft Foundry provisioning fails

Verify regional availability and quotas:

```bash
# Check if Foundry is available in westus3
az provider show --namespace Microsoft.MachineLearningServices --query "resourceTypes[?resourceType=='workspaces'].locations" -o table

# Check your subscription quota
az vm list-usage --location westus3 -o table
```

## 💰 Cost Estimation (Dev Environment)

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|----------------------|
| Container Registry | Basic | ~$5 |
| App Service Plan | B1 Linux | ~$13 |
| Application Insights | Pay-as-you-go | ~$2-5 |
| Log Analytics | Pay-as-you-go | ~$2 |
| Microsoft Foundry | Basic | Variable (usage-based) |
| **Total** | | **~$22-25** + AI usage |

> **Note**: Stop or delete resources when not in use to minimize costs.

## 🧹 Cleanup

Remove all resources:

```bash
# Delete all resources (prompts for confirmation)
azd down

# Delete resources without confirmation
azd down --force --purge
```

## 📚 Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Microsoft Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)

## 🤝 Support

For issues or questions:
1. Check the [troubleshooting section](#-troubleshooting) above
2. Review Azure deployment logs: `azd provision --debug`
3. Check Web App logs: `az webapp log tail`
4. Open an issue in the repository
