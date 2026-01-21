#!/bin/bash
set -e

echo "🧪 Testing Terraform configurations..."

# Test AWS configuration
echo ""
echo "1. Validating AWS Terraform..."
cd cloud/aws
terraform init -backend=false
terraform fmt -check -recursive || {
  echo "❌ Terraform formatting issues detected. Run 'terraform fmt -recursive' to fix."
  exit 1
}
terraform validate
echo "✅ AWS Terraform configuration is valid"
cd ../..

# Test GCP configuration
echo ""
echo "2. Validating GCP Terraform..."
cd cloud/gcp
terraform init -backend=false
terraform fmt -recursive
terraform fmt -check -recursive || {
  echo "❌ Terraform formatting issues detected. Run 'terraform fmt -recursive' to fix."
  exit 1
}
terraform validate
echo "✅ GCP Terraform configuration is valid"
cd ../..

echo ""
echo "✅ All Terraform configurations validated successfully!"
