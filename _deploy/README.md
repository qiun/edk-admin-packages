# EDK Admin Packages - Kubernetes Deployment

Dokumentacja wdrożenia aplikacji EDK Admin Packages na Kubernetes.

## Deployment przez GitLab CI/CD (Zalecane)

Aplikacja automatycznie deployowana jest przez GitLab CI/CD przy pushu do `master` lub `develop`.

### Konfiguracja GitLab Variables

W GitLab → Settings → CI/CD → Variables dodaj:

```
DOCKER_USER          - Username do docker.investimetric.io
DOCKER_PASSWORD      - Password do docker.investimetric.io
K8S_PROD            - Plik kubeconfig (base64 encoded)
```

### Automatyczny deployment

```bash
# Dodaj GitLab remote (już dodane)
git remote add gitlab git@gitlab.investimetric.io:edk/edk-donations.git

# Push do GitLab - automatycznie zbuduje i wdroży
git push gitlab master
```

Pipeline:
1. **docker** - buduje obraz Docker i pushuje do registry
2. **deploy-prod** - aplikuje ConfigMap i Deployment na Kubernetes

## Wymagania (Deployment manualny)

- Kubernetes cluster
- Docker registry: `docker.investimetric.io`
- kubectl skonfigurowany dla klastra
- Secret `docker-inv-auth` dla pull image z registry
- Secret `admin-packages-secrets` z wrażliwymi danymi
- PostgreSQL database na Kubernetes

## Struktura

```
_deploy/
├── edk-admin-packages.yaml     # Deployment + Service
├── admin-packages-config.yaml  # ConfigMap z ENV variables
├── .gitlab-ci.yml              # GitLab CI/CD pipeline
└── README.md                   # Ta dokumentacja
```

## Przygotowanie przed deploymentem

### 1. Baza danych PostgreSQL (zewnętrzna)

Aplikacja wymaga dostępu do PostgreSQL (baza poza Kubernetesem).

**Połączenie z bazą danych**:

```bash
# Połącz się z serwerem bazy danych
psql -h <database_host> -U <username> -d postgres

# Sprawdź istniejące bazy
\l

# Utwórz bazę dla nowej aplikacji (jeśli nie istnieje)
CREATE DATABASE edk_admin_packages;

# Utwórz użytkownika (jeśli nie istnieje)
CREATE USER edk_admin WITH PASSWORD 'secure_password';

# Nadaj uprawnienia
GRANT ALL PRIVILEGES ON DATABASE edk_admin_packages TO edk_admin;

# Połącz się z nową bazą
\c edk_admin_packages

# Nadaj uprawnienia do schema public
GRANT ALL ON SCHEMA public TO edk_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO edk_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO edk_admin;

# Wyjdź
\q
```

**Format DATABASE_URL dla zewnętrznej bazy**:
```
postgresql://edk_admin:secure_password@database_host:5432/edk_admin_packages
```

**WAŻNE**: Upewnij się że baza PostgreSQL jest dostępna z Kubernetes cluster:
- Skonfiguruj firewall aby zezwalał na połączenia z Kubernetes nodes
- Użyj publicznego IP lub domeny dostępnej z klastra
- Możesz użyć SSL dla bezpiecznego połączenia: `?sslmode=require`

### 2. Wygeneruj SECRET_KEY_BASE

```bash
# Wygeneruj nowy klucz dla Rails
docker run --rm ruby:3.4.5-slim bundle exec rails secret
# Skopiuj output i dodaj do secrets
```

## Secrets (muszą być utworzone ręcznie)

Utwórz secret `admin-packages-secrets` z wrażliwymi danymi:

```bash
kubectl create secret generic admin-packages-secrets \
  --from-literal=SECRET_KEY_BASE='your_secret_key_base' \
  --from-literal=DATABASE_URL='postgresql://user:password@host:5432/edk_packages_production' \
  --from-literal=PRZELEWY24_CRC_KEY='e4b020fec8e5bac1' \
  --from-literal=PRZELEWY24_API_KEY='74cb414be80b4ddfdd34758ad7b401e7' \
  --from-literal=APACZKA_APP_SECRET='fraibmznxzbsoumlilakp41k8vzuw1pt' \
  --from-literal=SMTP_PASSWORD='cjfmgplcrwjbcdlm'
```

Lub użyj pliku YAML:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-packages-secrets
type: Opaque
stringData:
  SECRET_KEY_BASE: "your_secret_key_base"
  DATABASE_URL: "postgresql://user:password@host:5432/edk_packages_production"
  PRZELEWY24_CRC_KEY: "e4b020fec8e5bac1"
  PRZELEWY24_API_KEY: "74cb414be80b4ddfdd34758ad7b401e7"
  APACZKA_APP_SECRET: "fraibmznxzbsoumlilakp41k8vzuw1pt"
  SMTP_PASSWORD: "cjfmgplcrwjbcdlm"
```

## Build i Push Docker Image

```bash
# Build image
docker build -t docker.investimetric.io/edk/edk-admin-packages:latest .

# Tag z wersją (np. v1.0.0)
docker tag docker.investimetric.io/edk/edk-admin-packages:latest \
  docker.investimetric.io/edk/edk-admin-packages:v1.0.0

# Push do registry
docker push docker.investimetric.io/edk/edk-admin-packages:latest
docker push docker.investimetric.io/edk/edk-admin-packages:v1.0.0
```

## Deployment

### 1. Utwórz ConfigMap

```bash
kubectl apply -f _deploy/admin-packages-config.yaml
```

### 2. Utwórz Secret (jeśli jeszcze nie istnieje)

```bash
kubectl apply -f admin-packages-secrets.yaml
```

### 3. Deploy aplikacji

```bash
# Zastąp TAG_PLACEHOLDER aktualną wersją
sed 's/TAG_PLACEHOLDER/v1.0.0/g' _deploy/edk-admin-packages.yaml | kubectl apply -f -
```

Lub edytuj plik i zastąp `TAG_PLACEHOLDER` konkretnym tagiem, potem:

```bash
kubectl apply -f _deploy/edk-admin-packages.yaml
```

## Weryfikacja

```bash
# Sprawdź status deploymentu
kubectl get deployment edk-admin-packages

# Sprawdź pody
kubectl get pods -l app=edk-admin-packages

# Sprawdź logi
kubectl logs -f deployment/edk-admin-packages

# Sprawdź service
kubectl get svc edk-admin-packages
```

## Update aplikacji

```bash
# Build nowej wersji
docker build -t docker.investimetric.io/edk/edk-admin-packages:v1.0.1 .
docker push docker.investimetric.io/edk/edk-admin-packages:v1.0.1

# Update deployment
kubectl set image deployment/edk-admin-packages \
  edk-admin-packages=docker.investimetric.io/edk/edk-admin-packages:v1.0.1

# Lub edytuj deployment i apply ponownie
kubectl apply -f _deploy/edk-admin-packages.yaml
```

## Rollback

```bash
# Sprawdź historię wdrożeń
kubectl rollout history deployment/edk-admin-packages

# Wróć do poprzedniej wersji
kubectl rollout undo deployment/edk-admin-packages

# Wróć do konkretnej rewizji
kubectl rollout undo deployment/edk-admin-packages --to-revision=2
```

## Skalowanie

```bash
# Skaluj do 3 replik
kubectl scale deployment edk-admin-packages --replicas=3

# Lub edytuj deployment YAML i zmień spec.replicas
```

## Troubleshooting

```bash
# Szczegółowe info o deployment
kubectl describe deployment edk-admin-packages

# Szczegółowe info o podzie
kubectl describe pod <pod-name>

# Logi z konkretnego poda
kubectl logs <pod-name>

# Logi z poprzedniego restartu
kubectl logs <pod-name> --previous

# Shell do poda (debugging)
kubectl exec -it <pod-name> -- /bin/bash

# Port forward do lokalnego testowania
kubectl port-forward deployment/edk-admin-packages 3000:3000
```

## Ingress / Load Balancer

Aby wystawić aplikację na zewnątrz, skonfiguruj Ingress lub LoadBalancer w zależności od infrastruktury klastra.

Przykład Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: edk-admin-packages-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
    - hosts:
        - pakiety.edk.org.pl
      secretName: pakiety-edk-tls
  rules:
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

## Database Migrations

Migracje są uruchamiane automatycznie przez `bin/docker-entrypoint` przy starcie kontenera.

Jeśli potrzebujesz uruchomić migracje ręcznie:

```bash
kubectl exec -it deployment/edk-admin-packages -- ./bin/rails db:migrate
```

## Monitorowanie

- **Health check**: `GET /up` (Rails 7.1+)
- **Liveness probe**: Sprawdza czy aplikacja odpowiada
- **Readiness probe**: Sprawdza czy aplikacja jest gotowa do przyjmowania requestów

## Zmienne środowiskowe

Wszystkie zmienne są zdefiniowane w:
- **ConfigMap** (`admin-packages-config`): Publiczne zmienne
- **Secret** (`admin-packages-secrets`): Wrażliwe dane (hasła, klucze API)

Aby zmienić ConfigMap:
```bash
kubectl edit configmap admin-packages-config
# Po zapisaniu, restart deployment:
kubectl rollout restart deployment/edk-admin-packages
```
