#!/usr/bin/env bash
set -e

# Azure Deployment Script for Sekha

RESOURCE_GROUP="${SEKHA_RG:-sekha-rg}"
LOCATION="${AZURE_LOCATION:-eastus}"
DB_PASSWORD="${SEKHA_DB_PASSWORD:-$(openssl rand -base64 32)}"

echo "🚀 Deploying Sekha to Azure..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo ""
echo "⚠️  SAVE YOUR DATABASE PASSWORD:"
echo "    $DB_PASSWORD"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Create resource group
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# Deploy infrastructure
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file deploy-azure.bicep \
  --parameters dbPassword="$DB_PASSWORD"

echo "✅ Deployment complete!"
echo ""
echo "Controller URL:"
az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name deploy-azure \
  --query properties.outputs.controllerUrl.value \
  --output tsv
