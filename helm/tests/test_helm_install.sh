#!/usr/bin/env bash
set -e

echo "🧪 Testing Helm Installation (requires Kind cluster)..."

# Create test cluster
kind create cluster --name sekha-test || true

# Install chart
helm install test-sekha helm/sekha-controller \
  --namespace sekha-test \
  --create-namespace \
  --wait \
  --timeout 5m

# Check deployment
kubectl get pods -n sekha-test
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sekha-controller -n sekha-test --timeout=300s

# Test health endpoint
kubectl port-forward -n sekha-test svc/test-sekha-sekha-controller 8080:8080 &
PF_PID=$!
sleep 5

curl -f http://localhost:8080/health || {
    echo "❌ Health check failed"
    kill $PF_PID
    exit 1
}

kill $PF_PID

# Cleanup
helm uninstall test-sekha -n sekha-test
kind delete cluster --name sekha-test

echo "✅ Helm installation test passed!"
