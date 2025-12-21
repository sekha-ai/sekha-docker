#!/usr/bin/env bash
set -e

# GCP Deployment Script for Sekha

PROJECT_ID="${GCP_PROJECT_ID:-}"
REGION="${GCP_REGION:-us-central1}"
DB_PASSWORD="${SEKHA_DB_PASSWORD:-$(openssl rand -base64 32)}"

if [ -z "$PROJECT_ID" ]; then
  echo "❌ GCP_PROJECT_ID environment variable required"
  exit 1
fi

echo "🚀 Deploying Sekha to GCP..."
echo "Project: $PROJECT_ID"
echo "Region: $REGION"

cd terraform

terraform init

terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="region=$REGION" \
  -var="db_password=$DB_PASSWORD" \
  -auto-approve

echo "✅ Deployment complete!"
echo ""
terraform output controller_url
