# Testowanie Webhook Przelewy24 - Instrukcja

## Konfiguracja Środowisk

### Development
- **Domena:** https://edk-pakiety.websiteinit.com
- **Webhook URL:** https://edk-pakiety.websiteinit.com/webhooks/przelewy24
- **Return URL:** https://edk-pakiety.websiteinit.com/cegielka/sukces
- **Przelewy24:** Produkcyjne klucze API (SANDBOX=false)

### Production (przyszłość)
- **Domena:** https://wspieram.edk.org.pl
- **Webhook URL:** https://wspieram.edk.org.pl/webhooks/przelewy24
- **Return URL:** https://wspieram.edk.org.pl/cegielka/sukces
- **Przelewy24:** Produkcyjne klucze API (SANDBOX=false)

---

## Proces Testowania End-to-End

### 1. Przygotowanie

Upewnij się, że:
- [ ] Serwer Rails działa: `bin/rails server`
- [ ] Domena edk-pakiety.websiteinit.com wskazuje na localhost:3000
- [ ] Plik .env ma poprawną konfigurację (zobacz poniżej)

### 2. Sprawdzenie Konfiguracji

```bash
# Sprawdź plik .env
cat .env | grep PRZELEWY24
```

Powinno pokazać:
```
PRZELEWY24_MERCHANT_ID=276306
PRZELEWY24_POS_ID=276306
PRZELEWY24_CRC_KEY=e4b020fec8e5bac1
PRZELEWY24_API_KEY=74cb414be80b4ddfdd34758ad7b401e7
PRZELEWY24_SANDBOX=false
PRZELEWY24_RETURN_URL=https://edk-pakiety.websiteinit.com/cegielka/sukces
PRZELEWY24_STATUS_URL=https://edk-pakiety.websiteinit.com/webhooks/przelewy24
```

### 3. Test Formularza Darowizny

1. Otwórz w przeglądarce: https://edk-pakiety.websiteinit.com/cegielka
2. Wypełnij formularz:
   - Ilość pakietów: np. 1
   - Email: twój prawdziwy email
   - Imię i Nazwisko
   - Telefon
   - [x] Chcę otrzymać upominek
   - Wybierz paczkomat InPost
   - [x] Akceptuję regulamin
3. Kliknij "Wpłać teraz"

**Oczekiwany rezultat:**
- Przekierowanie do strony płatności Przelewy24
- Status płatności w konsoli: `Creating Przelewy24 payment`

### 4. Płatność Przelewy24

1. Na stronie Przelewy24 wybierz metodę płatności
2. Wybierz "Płatność testowa" lub użyj karty testowej
3. Potwierdź płatność

**Dane testowe (jeśli SANDBOX=true):**
- Numer karty: `4444 3333 2222 1111`
- Data ważności: dowolna przyszła
- CVV: `123`

**UWAGA:** Masz SANDBOX=false, więc używasz produkcyjnego środowiska Przelewy24!

### 5. Monitorowanie Webhook

Otwórz drugi terminal i monitoruj logi Rails:

```bash
tail -f log/development.log | grep -E "(Przelewy24|webhook|Donation)"
```

**Czego szukać:**
```
Przelewy24 webhook received: {...}
Przelewy24 payment confirmed for donation #123
Queued shipment creation for donation #123
```

### 6. Weryfikacja w Rails Console

```bash
bin/rails console
```

```ruby
# Sprawdź ostatnią darowiznę
donation = Donation.last

# Sprawdź status płatności
donation.payment_status # => "paid"

# Sprawdź czy email został wysłany
ActionMailer::Base.deliveries.last

# Sprawdź czy shipment został utworzony
donation.shipment

# Sprawdź status shipment job
Apaczka::CreateShipmentJob
```

### 7. Sprawdzenie Email

Sprawdź email na adresie podanym w formularzu:
- [ ] Email "Dziękujemy za wsparcie EDK 2026!"
- [ ] Email z numerem przesyłki (gdy shipment job się wykona)

### 8. Sprawdzenie Wysyłki

```ruby
# W rails console
shipment = Shipment.last

# Sprawdź dane
shipment.status # => "label_printed" lub "pending"
shipment.waybill_number # => numer listu przewozowego
shipment.tracking_url # => link do śledzenia
shipment.apaczka_order_id # => ID w aPaczka

# Sprawdź źródło (Order lub Donation)
shipment.source # => #<Donation id: ...>
```

---

## Debugowanie Problemów

### Webhook nie działa

1. Sprawdź logi Rails:
```bash
tail -f log/development.log
```

2. Sprawdź czy webhook URL jest dostępny:
```bash
curl -X POST https://edk-pakiety.websiteinit.com/webhooks/przelewy24 \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'
```

3. Sprawdź routing:
```bash
bin/rails routes | grep webhook
```

Powinno pokazać:
```
POST /webhooks/przelewy24 public/webhooks#przelewy24
```

### Email nie wysyła się

Sprawdź konfigurację email w config/environments/development.rb:

```ruby
# Dla testów lokalnych (letter_opener)
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true

# Dla prawdziwych emaili (SMTP)
# config.action_mailer.delivery_method = :smtp
# config.action_mailer.smtp_settings = { ... }
```

### Shipment job nie wykonuje się

```bash
# Sprawdź czy są zakolejkowane joby
bin/rails console
Apaczka::CreateShipmentJob.perform_now(Shipment.last)
```

### SSL Verification Error

Jeśli widzisz błędy SSL:
```
OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0
```

Tymczasowo wyłączone w app/services/przelewy24/client.rb:103:
```ruby
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
```

**KRYTYCZNE:** To musi być naprawione przed produkcją!

---

## Checklist Testowania

- [ ] Formularz renderuje się poprawnie
- [ ] Walidacje działają (brak email, brak telefonu gdy want_gift)
- [ ] Wybór paczkomatu InPost działa
- [ ] Płatność rejestruje się w Przelewy24
- [ ] Przekierowanie do płatności działa
- [ ] Webhook otrzymuje powiadomienie od Przelewy24
- [ ] Status darowizny zmienia się na "paid"
- [ ] Email potwierdzający wysyła się
- [ ] Shipment tworzy się w bazie
- [ ] CreateShipmentJob wykonuje się
- [ ] Shipment wysyła się do aPaczka API
- [ ] Email z numerem przesyłki wysyła się
- [ ] Magazyn (Inventory) aktualizuje się
- [ ] Strona sukcesu pokazuje szczegóły

---

## Przejście na Produkcję

Przed wdrożeniem na https://wspieram.edk.org.pl:

1. **Aktualizuj .env:**
```bash
PRZELEWY24_RETURN_URL=https://wspieram.edk.org.pl/cegielka/sukces
PRZELEWY24_STATUS_URL=https://wspieram.edk.org.pl/webhooks/przelewy24
APP_URL=https://pakiety.edk.org.pl
PUBLIC_DONATION_URL=https://wspieram.edk.org.pl
```

2. **Napraw SSL Verification:**
Usuń `http.verify_mode = OpenSSL::SSL::VERIFY_NONE` z `app/services/przelewy24/client.rb`

3. **Skonfiguruj SMTP:**
Dodaj produkcyjne ustawienia email w .env

4. **Skonfiguruj aPaczka:**
Dodaj produkcyjne klucze aPaczka w .env

5. **Przetestuj ponownie:**
Wykonaj pełny test end-to-end na produkcji

---

## Kontakt i Wsparcie

W razie problemów:
- Sprawdź logi: `log/development.log`
- Rails console: `bin/rails console`
- Przelewy24 Panel: https://panel.przelewy24.pl
- aPaczka Panel: https://www.apaczka.pl
