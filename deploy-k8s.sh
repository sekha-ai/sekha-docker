#!/bin/bash
set -e

# Sekha Kubernetes Deployer
# Usage: ./deploy-k8s.sh [--helm] [--version VERSION] [--namespace NAMESPACE]

NAMESPACE="sekha"
VERSION="latest"
USE_HELM=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --helm)
            USE_HELM=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--helm] [--version VERSION] [--namespace NAMESPACE]"
            echo "  --helm       Deploy using Helm chart (default: kubectl)"
            echo "  --version    Specify version tag (default: latest)"
            echo "  --namespace  Kubernetes namespace (default: sekha)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🚀 Deploying Sekha to Kubernetes..."
echo "📋 Version: $VERSION"
echo "🎧 Namespace: $NAMESPACE"
echo "📦 Method: $([ \"$USE_HELM\" = true ] && echo 'Helm' || echo 'kubectl')"

# Create namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

if [ "$USE_HELM" = true ]; then
    # Deploy with Helm
    echo "📦 Deploying with Helm..."
    
    helm repo add sekha https://sekha-ai.github.io/helm-charts
    
    helm upgrade --install sekha \
        sekha/sekha-controller \
        --namespace "$NAMESPACE" \
        --set controller.image.tag="$VERSION" \
        --set bridge.image.tag="$VERSION" \
        --wait \
        --timeout 10m
    
    echo "✅ Helm deployment complete!"
    
else
    # Deploy with kubectl
    echo "📄 Deploying with kubectl..."
    
    # Apply manifests
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/pvc.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    
    # Wait for deployments
    echo "⏳ Waiting for deployments to be ready..."
    kubectl -n "$NAMESPACE" wait --for=condition=available --timeout=600s deployment/sekha-core
    kubectl -n "$NAMESPACE" wait --for=condition=available --timeout=600s deployment/sekha-bridge
    kubectl -n "$NAMESPACE" wait --for=condition=available --timeout=600s deployment/chroma
    kubectl -n "$NAMESPACE" wait --for=condition=available --timeout=600s deployment/redis
    
    echo "✅ kubectl deployment complete!"
fi

# Show status
echo ""
echo "📊 Pod Status:"
kubectl -n "$NAMESPACE" get pods

echo ""
echo "🔗 Services:"
kubectl -n "$NAMESPACE" get svc

echo ""
echo "📈 Check logs:"
echo "  kubectl -n $NAMESPACE logs -f deployment/sekha-core"
echo "  kubectl -n $NAMESPACE logs -f deployment/sekha-bridge"

echo ""
echo "🧹 Cleanup:"
echo "  kubectl delete namespace $NAMESPACE"
