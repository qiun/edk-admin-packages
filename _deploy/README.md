# Kubernetes Deployment - EDK Admin Packages

## Production Domains
- **Public Donations:** https://wspieram.edk.org.pl
- **Admin Panel:** https://pakiety.edk.org.pl

## Files
- `edk-admin-packages.yaml` - Deployment and Service
- `admin-packages-config.yaml` - ConfigMap (production values)
- `admin-packages-secrets.yaml.example` - Secrets template (DO NOT commit actual secrets!)
- `encode-secrets.sh` - Helper to encode secrets to base64
- `PRODUCTION_SECRETS_SETUP.md` - Detailed setup guide

## Quick Deploy

### 1. Create Secrets
```bash
cd _deploy/

# Use helper script
chmod +x encode-secrets.sh
./encode-secrets.sh

# Create secrets file from template
cp admin-packages-secrets.yaml.example admin-packages-secrets.yaml
vim admin-packages-secrets.yaml  # Add base64 values from script output

# Apply secrets
kubectl apply -f admin-packages-secrets.yaml
```

**See [PRODUCTION_SECRETS_SETUP.md](PRODUCTION_SECRETS_SETUP.md) for detailed instructions.**

### 2. Apply ConfigMap
```bash
kubectl apply -f admin-packages-config.yaml
```

### 3. Deploy Application
```bash
# Update image tag
sed -i 's/TAG_PLACEHOLDER/your-git-commit-hash/g' edk-admin-packages.yaml

# Deploy
kubectl apply -f edk-admin-packages.yaml
```

### 4. Verify
```bash
kubectl get pods -l app=edk-admin-packages
kubectl logs -l app=edk-admin-packages --tail=100
```

## Updates

### Update ConfigMap or Secrets
```bash
kubectl apply -f admin-packages-config.yaml
kubectl apply -f admin-packages-secrets.yaml

# Restart to apply changes
kubectl rollout restart deployment/edk-admin-packages
```

### Update Application
```bash
# Build and push new image
docker build -t docker.investimetric.io/edk/edk-admin-packages:NEW_TAG .
docker push docker.investimetric.io/edk/edk-admin-packages:NEW_TAG

# Update deployment
kubectl set image deployment/edk-admin-packages \
  edk-admin-packages=docker.investimetric.io/edk/edk-admin-packages:NEW_TAG

# Monitor
kubectl rollout status deployment/edk-admin-packages
```

## Database Migrations
```bash
POD=$(kubectl get pods -l app=edk-admin-packages -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- bin/rails db:migrate
```

## Troubleshooting
```bash
# Logs
kubectl logs -l app=edk-admin-packages --tail=200

# Pod status
kubectl describe pod -l app=edk-admin-packages

# Rails console
POD=$(kubectl get pods -l app=edk-admin-packages -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- bin/rails console
```

## Configuration Pattern

This deployment uses the same pattern as `edk-donations-refactor`:
- `envFrom` with ConfigMapRef and SecretRef
- Simple flat key-value configuration
- Docker image from `docker.investimetric.io` registry
- Image pull secret: `docker-inv-auth`

## Security
- ❌ Never commit `admin-packages-secrets.yaml` to git
- ✅ Use `encode-secrets.sh` to generate base64 values
- ✅ Rotate secrets regularly
- ✅ Enable RBAC for secret access
