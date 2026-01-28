#!/bin/bash
set -e

# EDK Admin Packages - Build & Push Script

VERSION=${1:-latest}
REGISTRY="docker.investimetric.io"
IMAGE_NAME="edk/edk-admin-packages"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${VERSION}"

echo "🔨 Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" ..

# Also tag as latest if version is specified
if [ "${VERSION}" != "latest" ]; then
  LATEST_IMAGE="${REGISTRY}/${IMAGE_NAME}:latest"
  echo "🏷️  Tagging as latest: ${LATEST_IMAGE}"
  docker tag "${FULL_IMAGE}" "${LATEST_IMAGE}"
fi

echo "✅ Build completed successfully!"
echo ""
echo "To push to registry:"
echo "  docker push ${FULL_IMAGE}"
if [ "${VERSION}" != "latest" ]; then
  echo "  docker push ${REGISTRY}/${IMAGE_NAME}:latest"
fi
echo ""
echo "To deploy to Kubernetes:"
echo "  sed 's/TAG_PLACEHOLDER/${VERSION}/g' edk-admin-packages.yaml | kubectl apply -f -"
