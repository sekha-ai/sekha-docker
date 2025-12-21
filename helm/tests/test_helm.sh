#!/usr/bin/env bash
set -e

echo "🧪 Testing Helm Chart..."

# Test 1: Lint chart
echo "1. Linting chart..."
helm lint helm/sekha-controller

# Test 2: Template rendering
echo "2. Rendering templates..."
helm template test-release helm/sekha-controller > /tmp/helm-output.yaml

# Test 3: Validate with kubeconform
echo "3. Validating manifests..."
if command -v kubeconform &> /dev/null; then
    kubeconform -strict -summary /tmp/helm-output.yaml
else
    echo "⚠️  kubeconform not installed, skipping validation"
fi

# Test 4: Template with custom values
echo "4. Testing custom values..."
cat > /tmp/test-values.yaml << EOF
replicaCount: 3
image:
  tag: v1.0.0
storage:
  size: 100Gi
EOF

helm template test-release helm/sekha-controller -f /tmp/test-values.yaml > /tmp/helm-custom.yaml

# Test 5: Check required fields
echo "5. Checking required fields..."
if ! grep -q "replicas: 3" /tmp/helm-custom.yaml; then
    echo "❌ ReplicaCount not applied"
    exit 1
fi

if ! grep -q "100Gi" /tmp/helm-custom.yaml; then
    echo "❌ Storage size not applied"
    exit 1
fi

echo "✅ All Helm tests passed!"
