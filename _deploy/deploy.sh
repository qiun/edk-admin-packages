#!/bin/bash
set -e

# EDK Admin Packages - Deploy Script

VERSION=${1:-latest}

if [ "${VERSION}" == "TAG_PLACEHOLDER" ]; then
  echo "❌ Error: Please specify a version tag"
  echo "Usage: ./deploy.sh <version>"
  echo "Example: ./deploy.sh v1.0.0"
  exit 1
fi

echo "🚀 Deploying EDK Admin Packages version: ${VERSION}"
echo ""

# Apply ConfigMap
echo "📝 Applying ConfigMap..."
kubectl apply -f admin-packages-config.yaml

# Check if secrets exist
if ! kubectl get secret admin-packages-secrets &> /dev/null; then
  echo "⚠️  Warning: Secret 'admin-packages-secrets' not found!"
  echo "Please create it before deploying. See README.md for instructions."
  exit 1
fi

# Deploy application
echo "🔄 Deploying application..."
sed "s/TAG_PLACEHOLDER/${VERSION}/g" edk-admin-packages.yaml | kubectl apply -f -

echo ""
echo "✅ Deployment completed!"
echo ""
echo "Check status with:"
echo "  kubectl get pods -l app=edk-admin-packages"
echo "  kubectl logs -f deployment/edk-admin-packages"
