# GitHub Actions Deployment Configuration

This workflow automatically builds and deploys the ZavaStorefront application to Azure App Service when changes are pushed to the `main` branch.

## Required Configuration

### 1. Create Azure Service Principal

Run this command to create a service principal with Contributor access to your resource group:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group-name> \
  --sdk-auth
```

Copy the entire JSON output - you'll need it for the GitHub secret.

### 2. Configure GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Create this secret:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AZURE_CREDENTIALS` | JSON output from service principal creation | Full JSON with clientId, clientSecret, subscriptionId, tenantId |

### 3. Configure GitHub Variables

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**

Create these variables:

| Variable Name | Value | How to Get |
|--------------|-------|------------|
| `AZURE_WEBAPP_NAME` | Your Web App name | `azd env get-values \| grep AZURE_WEB_APP_NAME` |
| `ACR_NAME` | Your Container Registry name | `azd env get-values \| grep AZURE_CONTAINER_REGISTRY_NAME` |

### 4. Get Values from Your Deployment

If you used `azd up` to deploy, retrieve the values with:

```bash
# Get Web App name
azd env get-values | grep AZURE_WEB_APP_NAME

# Get ACR name  
azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME

# Get Resource Group name
azd env get-values | grep AZURE_RESOURCE_GROUP
```

Or find them in the Azure Portal under your resource group.

## Testing the Workflow

1. Push changes to the `main` branch
2. Go to **Actions** tab in your repository
3. Watch the workflow run
4. Once complete, visit your App Service URL to see the changes

## Manual Trigger

You can also trigger the workflow manually:
1. Go to **Actions** tab
2. Select "Build and Deploy to Azure App Service"
3. Click **Run workflow**
