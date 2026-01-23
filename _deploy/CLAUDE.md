# Kubernetes Deployment Configuration

## Overview

Kubernetes deployment manifests for the EDK Admin Packages application, replacing the previous Next.js application at **https://wspieram.edk.org.pl/**

## Deployment Architecture

### Components

1. **Deployment** (`edk-admin-packages`)
   - 2 replicas for high availability
   - Rails 8 application with Thruster server
   - Exposes port 80 (container) → 3000 (service)
   - Environment variables from ConfigMap and Secrets
   - Health checks via `/up` endpoint

2. **Service** (`edk-admin-packages`)
   - ClusterIP type (internal only)
   - Port 3000 → forwards to container port 80
   - Selector: `app: edk-admin-packages`

3. **ConfigMap** (`admin-packages-config`)
   - Non-secret configuration values
   - Application URLs, public API keys
   - SMTP settings, Przelewy24 public config

4. **Secrets** (`admin-packages-secrets`)
   - Sensitive credentials (base64 encoded)
   - Database passwords, API keys, CRC keys
   - Rails secret key base

## Files Structure

```
_deploy/
├── README.md                              # Deployment guide
├── CLAUDE.md                              # This file
├── edk-admin-packages.yaml                # Deployment + Service
├── admin-packages-config.yaml             # ConfigMap
└── admin-packages-secrets.yaml.example    # Secrets template (never commit actual secrets!)
```

## Deployment Manifest Details

### Container Specification

```yaml
image: docker.investimetric.io/edk/edk-admin-packages:TAG_PLACEHOLDER
ports:
  - containerPort: 80
    name: http
```

**Important**: Replace `TAG_PLACEHOLDER` with actual git commit hash or version tag before deploying.

### Environment Variables Strategy

**From ConfigMap** (non-secret, public values):
- Application URLs (APP_URL, PUBLIC_DONATION_URL)
- Przelewy24 merchant ID and POS ID (public identifiers)
- SMTP server settings (addresses, ports)
- Email from address
- aPaczka app ID
- Feature flags (PRZELEWY24_SANDBOX, APACZKA_SANDBOX)

**From Secrets** (sensitive credentials):
- Database connection URL
- Przelewy24 CRC key and API key
- Rails SECRET_KEY_BASE
- aPaczka app secret
- SMTP username and password

This separation follows Kubernetes best practices:
- ConfigMaps can be versioned and shared
- Secrets are encrypted at rest
- Easy to rotate secrets without changing ConfigMap
- Clear distinction between public and private data

### Health Checks

#### Liveness Probe
```yaml
httpGet:
  path: /up
  port: 80
initialDelaySeconds: 30
periodSeconds: 10
timeoutSeconds: 5
failureThreshold: 3
```

**Purpose**: Detect if container is stuck or crashed. Kubernetes restarts pod on failure.

**Rails 8 `/up` endpoint**: Returns 200 OK if database connection works and Rails boots successfully.

#### Readiness Probe
```yaml
httpGet:
  path: /up
  port: 80
initialDelaySeconds: 10
periodSeconds: 5
timeoutSeconds: 3
failureThreshold: 3
```

**Purpose**: Detect if pod is ready to serve traffic. Kubernetes removes from Service endpoints if not ready.

**Use case**: During deployment rollout, new pods marked ready only after Rails fully initialized.

### Resource Limits

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

**Requests**: Guaranteed resources for pod scheduling
**Limits**: Maximum resources pod can consume

**Rationale**:
- Rails base memory ~300-400 MB
- Buffer for request processing and caching
- 250m CPU = 1/4 core minimum (sufficient for web app)
- 500m CPU limit prevents runaway processes
- Adjust based on production load testing

### Replica Count

```yaml
replicas: 2
```

**High Availability**:
- 2 pods ensure zero downtime during rolling updates
- If one pod crashes, other continues serving traffic
- Kubernetes automatically restarts failed pods

**Scaling**:
```bash
# Scale up
kubectl scale deployment edk-admin-packages --replicas=5

# Scale down
kubectl scale deployment edk-admin-packages --replicas=1

# Autoscaling (optional)
kubectl autoscale deployment edk-admin-packages --min=2 --max=10 --cpu-percent=80
```

## ConfigMap Configuration

### Application URLs

```yaml
APP_URL: "https://pakiety.edk.org.pl"
PUBLIC_DONATION_URL: "https://wspieram.edk.org.pl"
```

**APP_URL**: Admin panel and leader portal
**PUBLIC_DONATION_URL**: Public donation page (Cegiełka)

### Przelewy24 Public Configuration

```yaml
PRZELEWY24_MERCHANT_ID: "276306"
PRZELEWY24_POS_ID: "276306"
PRZELEWY24_SANDBOX: "false"
PRZELEWY24_RETURN_URL: "https://wspieram.edk.org.pl/cegielka/sukces"
PRZELEWY24_STATUS_URL: "https://wspieram.edk.org.pl/webhooks/przelewy24"
```

**Merchant/POS ID**: Public identifiers, not sensitive
**Return URL**: Where user redirects after payment
**Status URL**: Webhook endpoint for payment notifications

**Important**: These URLs must match Przelewy24 panel configuration!

### Email Configuration

```yaml
SMTP_ADDRESS: "smtp.gmail.com"
SMTP_PORT: "587"
SMTP_DOMAIN: "edk.org.pl"
SMTP_AUTHENTICATION: "plain"
SMTP_ENABLE_STARTTLS_AUTO: "true"
EMAIL_FROM: "noreply@edk.org.pl"
```

Non-secret SMTP settings. Credentials (username/password) stored in Secrets.

## Secrets Management

### Required Secrets

All values must be **base64 encoded**:

```bash
echo -n "your_secret_value" | base64
```

#### Przelewy24 Secrets

```yaml
PRZELEWY24_CRC_KEY: "base64_encoded_crc_key"
PRZELEWY24_API_KEY: "base64_encoded_api_key"
```

**Get from**: https://panel.przelewy24.pl/
**Security**: Never commit to git, rotate periodically

#### Database Connection

```yaml
DATABASE_URL: "base64_encoded_postgresql_url"
```

**Format**: `postgresql://username:password@host:port/database`
**Example**: `postgresql://edk_user:secret@postgres.example.com:5432/edk_production`

**Important**: URL includes password, so must be in Secrets not ConfigMap!

#### Rails Secret Key Base

```yaml
SECRET_KEY_BASE: "base64_encoded_secret_key"
```

**Generate**:
```bash
docker run --rm docker.investimetric.io/edk/edk-admin-packages:latest bin/rails secret
```

**Purpose**: Encrypts cookies, sessions, signed data
**Security**: Must remain constant across deployments, never expose publicly

#### aPaczka Integration

```yaml
APACZKA_APP_SECRET: "base64_encoded_app_secret"
```

**Get from**: https://www.apaczka.pl/
**Purpose**: Shipment API authentication

#### SMTP Credentials

```yaml
SMTP_USER_NAME: "base64_encoded_username"
SMTP_PASSWORD: "base64_encoded_password"
```

**Purpose**: Send transactional emails (donation confirmations, notifications)

### Secrets File Security

**CRITICAL**: Never commit actual secrets to git!

`.gitignore` includes:
```gitignore
_deploy/admin-packages-secrets.yaml
```

**Workflow**:
1. Copy `admin-packages-secrets.yaml.example` → `admin-packages-secrets.yaml`
2. Fill in base64-encoded values
3. Apply to Kubernetes: `kubectl apply -f admin-packages-secrets.yaml`
4. **Delete local copy** or store in secure vault

### Secrets Rotation

```bash
# 1. Create new secret values
# 2. Update secrets YAML with new base64-encoded values
# 3. Apply updated secrets
kubectl apply -f _deploy/admin-packages-secrets.yaml

# 4. Restart pods to use new secrets
kubectl rollout restart deployment/edk-admin-packages

# 5. Monitor rollout
kubectl rollout status deployment/edk-admin-packages
```

## Deployment Workflow

### Initial Deployment

```bash
# 1. Build and push Docker image
docker build -t docker.investimetric.io/edk/edk-admin-packages:v1.0.0 .
docker push docker.investimetric.io/edk/edk-admin-packages:v1.0.0

# 2. Create secrets (one-time)
cp _deploy/admin-packages-secrets.yaml.example _deploy/admin-packages-secrets.yaml
# Edit and fill in base64-encoded secrets
kubectl apply -f _deploy/admin-packages-secrets.yaml

# 3. Apply ConfigMap
kubectl apply -f _deploy/admin-packages-config.yaml

# 4. Update image tag in deployment
sed 's/TAG_PLACEHOLDER/v1.0.0/g' _deploy/edk-admin-packages.yaml | kubectl apply -f -

# 5. Run database migrations
kubectl run -it --rm rails-migrate \
  --image=docker.investimetric.io/edk/edk-admin-packages:v1.0.0 \
  --restart=Never \
  --env-from=configmap/admin-packages-config \
  --env-from=secret/admin-packages-secrets \
  -- bin/rails db:migrate

# 6. Verify deployment
kubectl get pods -l app=edk-admin-packages
kubectl logs -l app=edk-admin-packages --tail=50
```

### Rolling Updates

```bash
# 1. Build new version
docker build -t docker.investimetric.io/edk/edk-admin-packages:v1.0.1 .
docker push docker.investimetric.io/edk/edk-admin-packages:v1.0.1

# 2. Update deployment
kubectl set image deployment/edk-admin-packages \
  edk-admin-packages=docker.investimetric.io/edk/edk-admin-packages:v1.0.1

# 3. Watch rollout
kubectl rollout status deployment/edk-admin-packages

# 4. Run migrations if needed
# (same as step 5 above, with new image tag)

# 5. Rollback if issues
kubectl rollout undo deployment/edk-admin-packages
```

### Rolling Update Strategy

Kubernetes uses **RollingUpdate** strategy by default:

1. Start new pod with new version
2. Wait for readiness probe to pass
3. Add new pod to Service endpoints
4. Terminate old pod
5. Repeat until all pods updated

**Zero downtime**: Always at least 1 pod serving traffic during rollout.

## Docker Image

### Registry

```
docker.investimetric.io/edk/edk-admin-packages
```

**Authentication**: Requires credentials for pulling images in Kubernetes

**Image Pull Secret** (if needed):
```bash
kubectl create secret docker-registry investimetric-registry \
  --docker-server=docker.investimetric.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD
```

Then add to deployment:
```yaml
spec:
  imagePullSecrets:
  - name: investimetric-registry
```

### Dockerfile

Rails 8 default multi-stage Dockerfile:
- Base image: Ruby 3.4.5
- Multi-stage build: base → build → final
- Thruster proxy server (port 80)
- Non-root user (uid:gid 1000:1000)
- Jemalloc memory optimization

### Tagging Strategy

**Recommended**:
- Git commit hash: `v1.0.0-abc1234`
- Semantic version: `v1.0.0`, `v1.0.1`
- Latest tag: `latest` (always points to production)

**Example**:
```bash
TAG=$(git rev-parse --short HEAD)
docker build -t docker.investimetric.io/edk/edk-admin-packages:$TAG .
docker tag docker.investimetric.io/edk/edk-admin-packages:$TAG \
  docker.investimetric.io/edk/edk-admin-packages:latest
docker push docker.investimetric.io/edk/edk-admin-packages:$TAG
docker push docker.investimetric.io/edk/edk-admin-packages:latest
```

## Ingress Configuration

The deployment creates a **ClusterIP** service (internal only). You need an **Ingress** to route external traffic.

### Example Ingress (Nginx)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: edk-wspieram
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - wspieram.edk.org.pl
    secretName: wspieram-edk-tls
  rules:
  - host: wspieram.edk.org.pl
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: edk-admin-packages
            port:
              number: 3000
```

**Key points**:
- SSL/TLS via cert-manager and Let's Encrypt
- Automatic redirect HTTP → HTTPS
- Route all traffic from wspieram.edk.org.pl to service port 3000

### Multiple Domains

For admin panel at different domain (pakiety.edk.org.pl):

```yaml
rules:
- host: wspieram.edk.org.pl
  http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: edk-admin-packages
          port:
            number: 3000
- host: pakiety.edk.org.pl
  http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: edk-admin-packages
          port:
            number: 3000
```

Both domains route to same service, Rails routing handles path differentiation.

## Database Migrations

### During Deployment

**Option 1: One-off Job** (recommended)
```bash
kubectl run rails-migrate \
  --image=docker.investimetric.io/edk/edk-admin-packages:TAG \
  --restart=Never \
  --env-from=configmap/admin-packages-config \
  --env-from=secret/admin-packages-secrets \
  -- bin/rails db:migrate
```

**Option 2: Exec into Pod**
```bash
POD=$(kubectl get pods -l app=edk-admin-packages -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- bin/rails db:migrate
```

**Option 3: Init Container** (for automated migrations)
```yaml
initContainers:
- name: migrate
  image: docker.investimetric.io/edk/edk-admin-packages:TAG_PLACEHOLDER
  command: ["bin/rails", "db:migrate"]
  envFrom:
  - configMapRef:
      name: admin-packages-config
  - secretRef:
      name: admin-packages-secrets
```

### Migration Safety

**Before migration**:
1. Backup database
2. Test migrations in staging
3. Ensure backward compatibility (Rails supports this)

**Rails migration safe practices**:
- Use `safety_assured` for complex operations
- Add indexes concurrently (PostgreSQL)
- Avoid locking tables on high-traffic tables

## Monitoring and Debugging

### Check Deployment Status

```bash
# Deployment status
kubectl get deployment edk-admin-packages

# Pod status
kubectl get pods -l app=edk-admin-packages

# Detailed pod info
kubectl describe pod -l app=edk-admin-packages

# Service endpoints
kubectl get endpoints edk-admin-packages
```

### View Logs

```bash
# All pods
kubectl logs -l app=edk-admin-packages --tail=100 -f

# Specific pod
kubectl logs POD_NAME --tail=100 -f

# Previous crashed container
kubectl logs POD_NAME --previous
```

### Rails Console Access

```bash
POD=$(kubectl get pods -l app=edk-admin-packages -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- bin/rails console
```

**Use cases**:
- Check donation status
- Verify payment integration
- Debug data issues
- Test Przelewy24 client manually

### Test Database Connection

```bash
kubectl exec -it $POD -- bin/rails runner \
  "puts ActiveRecord::Base.connection.execute('SELECT version()').first"
```

### Verify Environment Variables

```bash
# Check specific ENV var
kubectl exec -it $POD -- env | grep PRZELEWY24

# Check all ENV vars
kubectl exec -it $POD -- env | sort
```

## Migration from Next.js Application

This deployment **replaces** the existing Next.js application at https://wspieram.edk.org.pl/

### Pre-Migration Checklist

- [ ] Backup Next.js database
- [ ] Export donation data from old system
- [ ] Document Przelewy24 webhook configuration
- [ ] Note any custom Ingress rules
- [ ] Backup SSL certificates (if manually managed)
- [ ] Document DNS configuration

### Migration Steps

1. **Deploy Rails app alongside Next.js** (different service name)
2. **Import data** from Next.js database to Rails database
3. **Test payment flow** end-to-end in production
4. **Update Ingress** to point to new Rails service
5. **Monitor** for 24 hours
6. **Scale down** Next.js deployment (keep for rollback)
7. **Delete Next.js** resources after 7 days of stability

### Rollback Plan

If issues arise:

```bash
# 1. Revert Ingress to point back to Next.js service
kubectl apply -f old-ingress-config.yaml

# 2. Scale down Rails app
kubectl scale deployment edk-admin-packages --replicas=0

# 3. Verify Next.js is serving traffic
curl -I https://wspieram.edk.org.pl/

# 4. Investigate Rails issues
kubectl logs -l app=edk-admin-packages --tail=500
```

## Production Readiness Checklist

### Before First Deploy

- [ ] All secrets created in Kubernetes
- [ ] Database created and accessible
- [ ] Przelewy24 production credentials configured
- [ ] Webhook URL registered in Przelewy24 panel
- [ ] aPaczka production credentials configured
- [ ] SMTP credentials tested
- [ ] SSL certificate configured (cert-manager or manual)
- [ ] DNS pointing to Kubernetes Ingress
- [ ] Backup strategy configured
- [ ] Monitoring alerts configured

### Post-Deploy Verification

- [ ] Health check endpoint responding: `curl https://wspieram.edk.org.pl/up`
- [ ] Admin login works
- [ ] Leader login works
- [ ] Donation form accessible
- [ ] Przelewy24 payment flow works (test transaction)
- [ ] Webhook delivery confirmed
- [ ] Email sending works
- [ ] InPost parcel locker selection works
- [ ] Database migrations applied
- [ ] No errors in logs

### Ongoing Maintenance

- [ ] Monitor pod CPU/memory usage
- [ ] Review logs for errors daily
- [ ] Rotate secrets quarterly
- [ ] Update Ruby/Rails versions
- [ ] Keep Kubernetes manifests versioned
- [ ] Test disaster recovery procedures
- [ ] Monitor payment success rate
- [ ] Review webhook delivery metrics

## Security Considerations

1. **Secrets Management**
   - Never commit secrets to git
   - Use Kubernetes Secrets, not ConfigMaps
   - Rotate secrets regularly
   - Audit secret access

2. **Network Security**
   - ClusterIP service (not exposed externally)
   - Ingress handles TLS termination
   - Force HTTPS redirect
   - Consider Network Policies

3. **Container Security**
   - Non-root user in Dockerfile
   - Minimal base image
   - Regular security updates
   - Scan images for vulnerabilities

4. **Application Security**
   - Przelewy24 signature verification
   - CSRF protection (Rails default)
   - SQL injection prevention (ActiveRecord)
   - XSS protection (Rails default)

## Performance Tuning

### Horizontal Scaling

```bash
# Manual scaling
kubectl scale deployment edk-admin-packages --replicas=5

# Auto-scaling based on CPU
kubectl autoscale deployment edk-admin-packages \
  --min=2 --max=10 --cpu-percent=70
```

### Database Connection Pooling

Configure in Rails `database.yml`:
```yaml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>
```

For 2 pods with 5 threads each: 10 concurrent database connections.

### Caching

Enable Redis for session store and cache:
```yaml
# In ConfigMap
REDIS_URL: "redis://redis-service:6379/0"
```

Configure Rails `config/environments/production.rb`:
```ruby
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
config.session_store :cache_store, key: '_edk_session'
```

## Troubleshooting

### Pod Crash Loop

```bash
# Check pod events
kubectl describe pod POD_NAME

# Check previous logs
kubectl logs POD_NAME --previous

# Common causes:
# - Database connection failure
# - Missing SECRET_KEY_BASE
# - Failed migrations
# - Port already in use
```

### Webhook Not Received

```bash
# Check service endpoints
kubectl get endpoints edk-admin-packages

# Check Ingress
kubectl describe ingress edk-wspieram

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never \
  -- curl http://edk-admin-packages:3000/up

# Check Przelewy24 panel for webhook delivery status
```

### Database Connection Issues

```bash
# Test connection from pod
kubectl exec -it $POD -- bin/rails runner \
  "puts ActiveRecord::Base.connection.active?"

# Check DATABASE_URL is set correctly
kubectl exec -it $POD -- env | grep DATABASE_URL

# Verify database host is reachable
kubectl exec -it $POD -- nc -zv DATABASE_HOST 5432
```

## References

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Rails Docker Guide](https://guides.rubyonrails.org/docker.html)
