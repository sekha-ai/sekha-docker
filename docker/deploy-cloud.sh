#!/bin/bash
set -e

# ============================================
# Sekha Cloud Deployer (Tier 3)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDER="${1:-aws}"
DEPLOY_TYPE="${2:-docker}"
CLUSTER_NAME="${SEKHA_CLUSTER:-sekha-cluster}"
REGION="${SEKHA_REGION:-us-west-2}"

echo "☁️  Deploying Sekha to $PROVIDER ($DEPLOY_TYPE)..."

case "$PROVIDER" in
    aws)
        deploy_aws
        ;;
    gcp)
        deploy_gcp
        ;;
    azure)
        deploy_azure
        ;;
    *)
        echo "❌ Unsupported provider: $PROVIDER"
        echo "   Supported: aws, gcp, azure"
        exit 1
        ;;
esac

deploy_aws() {
    if ! command -v aws >/dev/null 2>&1; then
        echo "❌ AWS CLI required"
        exit 1
    fi

    echo "🔧 Configuring AWS deployment..."
    
    # Create EKS cluster if needed
    if ! eksctl get cluster --name "$CLUSTER_NAME" >/dev/null 2>&1; then
        echo "🔄 Creating EKS cluster: $CLUSTER_NAME"
        eksctl create cluster \
            --name "$CLUSTER_NAME" \
            --region "$REGION" \
            --nodes 2 \
            --node-type t3.large \
            --managed
    fi

    # Update kubeconfig
    eksctl utils write-kubeconfig --cluster="$CLUSTER_NAME" --region="$REGION"

    # Deploy based on type
    case "$DEPLOY_TYPE" in
        docker)
            deploy_aws_ecs
            ;;
        k8s)
            deploy_aws_eks
            ;;
        *)
            echo "❌ Unsupported deploy type: $DEPLOY_TYPE"
            exit 1
            ;;
    esac
}

deploy_aws_ecs() {
    echo "🐳 Deploying to ECS Fargate..."
    
    # Create ECS cluster
    aws ecs create-cluster --cluster-name sekha-cluster >/dev/null 2>&1 || true
    
    # Deploy using docker-compose -> ECS conversion
    docker context create ecs sekha-ecs || true
    docker context use sekha-ecs
    
    # Deploy
    docker compose up -d
    
    echo "✅ Deployed to ECS Fargate"
}

deploy_aws_eks() {
    echo "☸️  Deploying to EKS..."
    
    # Add AWS Load Balancer Controller if needed
    helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1
    helm repo update >/dev/null 2>&1
    
    # Deploy with Helm
    deploy_helm
    
    echo "✅ Deployed to EKS"
}

deploy_gcp() {
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "❌ gcloud CLI required"
        exit 1
    fi

    echo "🔧 Configuring GCP deployment..."
    
    case "$DEPLOY_TYPE" in
        docker)
            deploy_gcp_cloud_run
            ;;
        k8s)
            deploy_gcp_gke
            ;;
        *)
            echo "❌ Unsupported deploy type: $DEPLOY_TYPE"
            exit 1
            ;;
    esac
}

deploy_gcp_cloud_run() {
    echo "🚀 Deploying to Cloud Run..."
    
    # Set project
    PROJECT_ID=$(gcloud config get-value project)
    
    # Build and push images
    gcloud builds submit --config=cloudbuild.yaml
    
    # Deploy Rust core
    gcloud run deploy sekha-controller \
        --image="gcr.io/$PROJECT_ID/sekha-controller:latest" \
        --platform=managed \
        --region="$REGION" \
        --allow-unauthenticated \
        --memory=1Gi \
        --cpu=1
    
    # Deploy Python bridge
    gcloud run deploy sekha-bridge \
        --image="gcr.io/$PROJECT_ID/sekha-bridge:latest" \
        --platform=managed \
        --region="$REGION" \
        --allow-unauthenticated \
        --memory=2Gi \
        --cpu=2
    
    echo "✅ Deployed to Cloud Run"
}

deploy_gcp_gke() {
    echo "☸️  Deploying to GKE..."
    
    # Get credentials
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION"
    
    # Deploy with Helm
    deploy_helm
    
    echo "✅ Deployed to GKE"
}

deploy_azure() {
    if ! command -v az >/dev/null 2>&1; then
        echo "❌ Azure CLI required"
        exit 1
    fi

    echo "🔧 Configuring Azure deployment..."
    
    case "$DEPLOY_TYPE" in
        docker)
            deploy_azure_container_instances
            ;;
        k8s)
            deploy_azure_aks
            ;;
        *)
            echo "❌ Unsupported deploy type: $DEPLOY_TYPE"
            exit 1
            ;;
    esac
}

deploy_azure_container_instances() {
    echo "📦 Deploying to Container Instances..."
    
    # Create resource group if needed
    az group create --name sekha-rg --location "$REGION" >/dev/null 2>&1 || true
    
    # Deploy Redis first
    az container create \
        --resource-group sekha-rg \
        --name sekha-redis \
        --image redis:7-alpine \
        --ports 6379 \
        --memory 0.5 \
        --cpu 0.5 >/dev/null
    
    REDIS_IP=$(az container show --resource-group sekha-rg --name sekha-redis --query ipAddress.ip --output tsv)
    
    # Deploy Chroma
    az container create \
        --resource-group sekha-rg \
        --name sekha-chroma \
        --image chromadb/chroma:latest \
        --ports 8000 \
        --memory 1 \
        --cpu 1 >/dev/null
    
    CHROMA_IP=$(az container show --resource-group sekha-rg --name sekha-chroma --query ipAddress.ip --output tsv)
    
    # Deploy Rust core
    az container create \
        --resource-group sekha-rg \
        --name sekha-controller \
        --image "ghcr.io/sekha-ai/controller:$SEKHA_VERSION" \
        --ports 8080 \
        --memory 1 \
        --cpu 1 \
        --environment-variables \
            SEKHA_DATABASE_URL="sqlite:///data/sekha.db" \
            SEKHA_CHROMA_URL="http://$CHROMA_IP:8000" \
            SEKHA_OLLAMA_URL="http://ollama:11434" \
            REDIS_URL="redis://$REDIS_IP:6379/0" >/dev/null
    
    echo "✅ Deployed to Container Instances"
}

deploy_azure_aks() {
    echo "☸️  Deploying to AKS..."
    
    # Get credentials
    az aks get-credentials --resource-group sekha-rg --name "$CLUSTER_NAME"
    
    # Deploy with Helm
    deploy_helm
    
    echo "✅ Deployed to AKS"
}

deploy_helm() {
    echo "📦 Deploying with Helm..."
    
    # Create namespace
    kubectl create namespace sekha --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Helm repos
    helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1
    helm repo update >/dev/null 2>&1
    
    # Deploy Redis
    helm upgrade --install sekha-redis bitnami/redis \
        --namespace sekha \
        --set auth.enabled=false \
        --wait >/dev/null
    
    # Deploy dependencies
    kubectl apply -f "$SCRIPT_DIR/k8s/"
    
    # Wait for dependencies
    kubectl wait --for=condition=available --timeout=300s deployment/chroma -n sekha
    kubectl wait --for=condition=available --timeout=300s deployment/redis -n sekha
    
    # Deploy Sekha
    helm upgrade --install sekha "$SCRIPT_DIR/helm/sekha-controller" \
        --namespace sekha \
        --wait
    
    echo "✅ Helm deployment complete"
}

# Show help if no args
if [ $# -eq 0 ]; then
    echo "Usage: $0 <aws|gcp|azure> <docker|k8s>"
    echo ""
    echo "Examples:"
    echo "  $0 aws docker      # Deploy to AWS ECS"
    echo "  $0 aws k8s         # Deploy to AWS EKS"
    echo "  $0 gcp docker      # Deploy to Cloud Run"
    echo "  $0 gcp k8s         # Deploy to GKE"
    exit 0
fi

echo ""
echo "🎉 Deployment complete!"
echo ""