#!/usr/bin/env bash
set -e

echo "🧪 Testing Terraform configurations..."

# Test AWS
echo "1. Validating AWS Terraform..."
cd cloud/aws
terraform init -backend=false
terraform validate
terraform fmt -check
cd ../..

# Test GCP
echo "2. Validating GCP Terraform..."
cd cloud/gcp/terraform
terraform init -backend=false
terraform validate
terraform fmt -check
cd ../../..

echo "✅ All Terraform validation passed!"
