# Konfiguracja aPaczka.pl

## Credentials

Dodaj następującą konfigurację do `config/credentials.yml.enc`:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Dodaj:

```yaml
apaczka:
  app_id: "your_app_id_here"
  app_secret: "your_app_secret_here"
  sender:
    name: "EDK Koordynacja"
    street: "ul. Przykładowa 1"
    city: "Warszawa"
    post_code: "00-001"
    phone: "123456789"
    email: "kontakt@edk.pl"
```

## Środowisko Sandbox

Dla testów użyj sandbox credentials z aPaczka:

```yaml
apaczka:
  app_id: "sandbox_app_id"
  app_secret: "sandbox_app_secret"
  # ... reszta konfiguracji
```

## Uzyskanie credentials

1. Zarejestruj się na https://www.apaczka.pl
2. Przejdź do API Settings
3. Wygeneruj App ID i App Secret
4. Dla środowiska sandbox użyj dedykowanych credentials testowych

## Weryfikacja

Sprawdź czy credentials działają:

```bash
bin/rails runner "client = Apaczka::Client.new; puts client.inspect"
```

Jeśli widzisz obiekt klienta bez błędów - konfiguracja jest poprawna!
