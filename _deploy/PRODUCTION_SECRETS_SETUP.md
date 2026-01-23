# Production Secrets Setup Guide

## Przygotowanie Secrets dla Kubernetes (PRODUCTION)

Ten przewodnik opisuje jak skonfigurować secrets Kubernetes dla środowiska produkcyjnego na domenie **wspieram.edk.org.pl**.

---

## Krok 1: Przygotowanie Wartości

### Przelewy24 (Produkcja)

Aktualne dane (z .env development):
```bash
PRZELEWY24_MERCHANT_ID=276306
PRZELEWY24_POS_ID=276306
PRZELEWY24_CRC_KEY=e4b020fec8e5bac1
PRZELEWY24_API_KEY=74cb414be80b4ddfdd34758ad7b401e7
```

Panel zarządzania: https://panel.przelewy24.pl/

### aPaczka.pl (Produkcja)

Dane do uzupełnienia:
```bash
APACZKA_APP_ID=<your_production_app_id>
APACZKA_APP_SECRET=<your_production_app_secret>
```

Panel zarządzania: https://www.apaczka.pl/

### Database (PostgreSQL Production)

Format URL:
```bash
DATABASE_URL=postgresql://username:password@host:port/database
```

Przykład:
```bash
DATABASE_URL=postgresql://edk_user:SecurePassword123@postgres-prod.example.com:5432/edk_packages_production
```

### Rails Secret Key Base

Wygeneruj nowy klucz dla produkcji:
```bash
bin/rails secret
```

### SMTP Credentials (Gmail lub inny dostawca)

Dla Gmail App Password:
```bash
SMTP_USER_NAME=your-email@gmail.com
SMTP_PASSWORD=your-16-char-app-password
```

Dla Postmark/SendGrid (zalecane dla produkcji):
```bash
SMTP_USER_NAME=your-postmark-token
SMTP_PASSWORD=your-postmark-token
SMTP_ADDRESS=smtp.postmarkapp.com
```

---

## Krok 2: Kodowanie Base64

Każda wartość musi być zakodowana w Base64 przed dodaniem do secrets.

### Skrypt pomocniczy

Stwórz plik `encode-secrets.sh`:

```bash
#!/bin/bash
# encode-secrets.sh - Helper script to encode secrets

echo "=== EDK Admin Packages - Secret Encoder ==="
echo ""

# Przelewy24
echo "PRZELEWY24_CRC_KEY:"
echo -n "e4b020fec8e5bac1" | base64
echo ""

echo "PRZELEWY24_API_KEY:"
echo -n "74cb414be80b4ddfdd34758ad7b401e7" | base64
echo ""

# Database (EXAMPLE - replace with actual values)
echo "DATABASE_URL (EXAMPLE):"
echo -n "postgresql://edk_user:password@postgres:5432/edk_production" | base64
echo ""

# Secret Key Base (generate with: bin/rails secret)
echo "SECRET_KEY_BASE (EXAMPLE - generate new):"
echo -n "$(bin/rails secret)" | base64
echo ""

# aPaczka (TODO: Add production values)
echo "APACZKA_APP_SECRET (PLACEHOLDER):"
echo -n "your_apaczka_secret_here" | base64
echo ""

# SMTP
echo "SMTP_USER_NAME (EXAMPLE):"
echo -n "noreply@edk.org.pl" | base64
echo ""

echo "SMTP_PASSWORD (EXAMPLE):"
echo -n "your_smtp_password_here" | base64
echo ""

echo "=== Done ==="
```

### Użycie:

```bash
chmod +x encode-secrets.sh
./encode-secrets.sh
```

### Ręczne kodowanie:

```bash
# Przykład - CRC Key
echo -n "e4b020fec8e5bac1" | base64
# Wynik: ZTRiMDIwZmVjOGU1YmFjMQ==

# Przykład - API Key
echo -n "74cb414be80b4ddfdd34758ad7b401e7" | base64
# Wynik: NzRjYjQxNGJlODBiNGRkZmRkMzQ3NThhZDdiNDAxZTc=
```

---

## Krok 3: Utworzenie Pliku Secrets

Skopiuj template i wypełnij wartościami:

```bash
cd _deploy/
cp admin-packages-secrets.yaml.example admin-packages-secrets.yaml
```

Edytuj `admin-packages-secrets.yaml` i zamień wszystkie `your_base64_encoded_*` na faktyczne zakodowane wartości:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-packages-secrets
  namespace: default  # Update if using different namespace
type: Opaque
data:
  # Przelewy24 Secrets (PRODUCTION)
  PRZELEWY24_CRC_KEY: "ZTRiMDIwZmVjOGU1YmFjMQ=="
  PRZELEWY24_API_KEY: "NzRjYjQxNGJlODBiNGRkZmRkMzQ3NThhZDdiNDAxZTc="

  # Database URL (PRODUCTION)
  DATABASE_URL: "<base64_encoded_database_url>"

  # Rails Secret Key Base (PRODUCTION - generate new!)
  SECRET_KEY_BASE: "<base64_encoded_secret_key_base>"

  # aPaczka API Secret (PRODUCTION)
  APACZKA_APP_SECRET: "<base64_encoded_apaczka_secret>"

  # SMTP Credentials (PRODUCTION)
  SMTP_USER_NAME: "<base64_encoded_smtp_username>"
  SMTP_PASSWORD: "<base64_encoded_smtp_password>"
```

---

## Krok 4: Weryfikacja Secrets

Przed zastosowaniem sprawdź czy wszystkie wartości są poprawnie zakodowane:

```bash
# Test dekodowania
echo "ZTRiMDIwZmVjOGU1YmFjMQ==" | base64 -d
# Powinno pokazać: e4b020fec8e5bac1
```

---

## Krok 5: Zastosowanie w Kubernetes

### Sprawdź połączenie z klastrem:

```bash
kubectl cluster-info
kubectl get nodes
```

### Zastosuj ConfigMap (publiczne wartości):

```bash
kubectl apply -f admin-packages-config.yaml
```

Sprawdź:
```bash
kubectl get configmap admin-packages-config -o yaml
```

### Zastosuj Secrets (wartości wrażliwe):

```bash
kubectl apply -f admin-packages-secrets.yaml
```

Sprawdź (NIE pokaże wartości jawnych):
```bash
kubectl get secret admin-packages-secrets
kubectl describe secret admin-packages-secrets
```

### Sprawdź konkretną wartość (dla weryfikacji):

```bash
# Pokazuje zakodowaną wartość
kubectl get secret admin-packages-secrets -o jsonpath='{.data.PRZELEWY24_CRC_KEY}'

# Dekoduje i pokazuje jawną wartość (OSTROŻNIE!)
kubectl get secret admin-packages-secrets -o jsonpath='{.data.PRZELEWY24_CRC_KEY}' | base64 -d
```

---

## Krok 6: Deploy Aplikacji

Po zaktualizowaniu secrets, wdróż aplikację:

```bash
# Update image tag in edk-admin-packages.yaml first
# Then apply:
kubectl apply -f edk-admin-packages.yaml
```

Sprawdź status:
```bash
kubectl get pods -l app=edk-admin-packages
kubectl logs -l app=edk-admin-packages --tail=100
```

---

## Krok 7: Weryfikacja Produkcji

### Sprawdź czy zmienne środowiskowe są dostępne w podzie:

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=edk-admin-packages -o jsonpath='{.items[0].metadata.name}')

# Check environment variables (without showing secrets)
kubectl exec $POD_NAME -- env | grep -E "APP_URL|PUBLIC_DONATION|PRZELEWY24_MERCHANT"
```

Powinno pokazać:
```
APP_URL=https://pakiety.edk.org.pl
PUBLIC_DONATION_URL=https://wspieram.edk.org.pl
PRZELEWY24_MERCHANT_ID=276306
```

### Test webhook URL:

```bash
curl -X POST https://wspieram.edk.org.pl/webhooks/przelewy24 \
  -H "Content-Type: application/json" \
  -d '{"test": "ping"}'
```

### Test strony cegiełki:

```bash
curl -I https://wspieram.edk.org.pl/cegielka
```

---

## Krok 8: Aktualizacja Secrets (w przyszłości)

Jeśli musisz zaktualizować secret:

```bash
# 1. Edytuj admin-packages-secrets.yaml
vim admin-packages-secrets.yaml

# 2. Zastosuj zmiany
kubectl apply -f admin-packages-secrets.yaml

# 3. Restartuj pody aby załadowały nowe wartości
kubectl rollout restart deployment/edk-admin-packages

# 4. Sprawdź status
kubectl rollout status deployment/edk-admin-packages
```

---

## Security Best Practices

### ✅ DO:
- Generuj nowy SECRET_KEY_BASE dla produkcji
- Używaj silnych haseł do bazy danych
- Przechowuj backup secrets w bezpiecznym miejscu (1Password, Vault)
- Regularnie rotuj hasła i tokeny
- Używaj RBAC do ograniczenia dostępu do secrets
- Szyfruj secrets at rest w Kubernetes (włącz encryption provider)

### ❌ DON'T:
- NIE commituj `admin-packages-secrets.yaml` do git (jest w .gitignore)
- NIE udostępniaj base64 encoded secrets publicznie
- NIE używaj tych samych secrets dla development i production
- NIE loguj secrets w aplikacji
- NIE używaj weak passwords

---

## Troubleshooting

### Secret nie jest widoczny w podzie:

```bash
# Sprawdź czy secret istnieje
kubectl get secret admin-packages-secrets

# Sprawdź czy deployment ma poprawne referencje
kubectl get deployment edk-admin-packages -o yaml | grep -A 5 secretKeyRef
```

### Błąd "secret not found":

```bash
# Upewnij się że namespace jest poprawny
kubectl get secret admin-packages-secrets -n default
kubectl get secret admin-packages-secrets -n <your-namespace>
```

### Błąd dekodowania base64:

```bash
# Sprawdź czy wartość jest poprawnie zakodowana
echo -n "test_value" | base64
# Powinno pokazać: dGVzdF92YWx1ZQ==

# Sprawdź dekodowanie
echo "dGVzdF92YWx1ZQ==" | base64 -d
# Powinno pokazać: test_value
```

---

## Quick Reference

### Aktualne Wartości Produkcyjne:

| Parametr | Wartość | Typ |
|----------|---------|-----|
| APP_URL | `https://pakiety.edk.org.pl` | ConfigMap |
| PUBLIC_DONATION_URL | `https://wspieram.edk.org.pl` | ConfigMap |
| PRZELEWY24_MERCHANT_ID | `276306` | ConfigMap |
| PRZELEWY24_POS_ID | `276306` | ConfigMap |
| PRZELEWY24_SANDBOX | `false` | ConfigMap |
| PRZELEWY24_RETURN_URL | `https://wspieram.edk.org.pl/cegielka/sukces` | ConfigMap |
| PRZELEWY24_STATUS_URL | `https://wspieram.edk.org.pl/webhooks/przelewy24` | ConfigMap |
| PRZELEWY24_CRC_KEY | `e4b020fec8e5bac1` | **Secret** |
| PRZELEWY24_API_KEY | `74cb414be80b4ddfdd34758ad7b401e7` | **Secret** |

### Przydatne Komendy:

```bash
# Lista wszystkich secrets
kubectl get secrets

# Szczegóły secret (bez wartości)
kubectl describe secret admin-packages-secrets

# Edycja secret (inline)
kubectl edit secret admin-packages-secrets

# Usunięcie secret
kubectl delete secret admin-packages-secrets

# Ponowne utworzenie
kubectl apply -f admin-packages-secrets.yaml
```
