# aPaczka.pl Sandbox Testing Guide - InPost Paczkomat

## 🎯 Cel

Ten dokument opisuje jak przetestować integrację z aPaczka.pl w środowisku sandbox (testowym) dla usługi dostawy do **paczkomatów InPost** (INPOST_COURIER_POINT).

## 📋 Wymagania wstępne

### 1. Uzyskanie credentials sandbox

**Sposób 1: Kontakt z supportem aPaczka**
1. Zaloguj się na [https://panel.apaczka.pl](https://panel.apaczka.pl)
2. Skontaktuj się z supportem aPaczka:
   - Email: support@apaczka.pl
   - Telefon: +48 61 657 57 77
3. Poproś o:
   - **App ID** dla środowiska testowego (sandbox)
   - **App Secret** dla środowiska testowego
   - Potwierdzenie że konto ma włączony dostęp do Web API v2

**Sposób 2: Panel Web API**
1. Przejdź do: Panel aPaczka → Ustawienia → Web API
2. Utwórz nową aplikację testową
3. Skopiuj wygenerowane **App ID** i **App Secret**

### 2. Konfiguracja środowiska

#### Development (.env)
```bash
# aPaczka Sandbox Credentials
APACZKA_APP_ID=your_sandbox_app_id_here
APACZKA_APP_SECRET=your_sandbox_app_secret_here
APACZKA_SANDBOX=true
```

#### Rails Credentials (production/staging)
```bash
# Edytuj credentials
EDITOR=nano rails credentials:edit

# Dodaj sekcję aPaczka
apaczka:
  app_id: your_sandbox_app_id
  app_secret: your_sandbox_app_secret
  sandbox: true
  sender:
    name: "EDK Koordynacja"
    street: "ul. Przykładowa 1"
    city: "Warszawa"
    post_code: "00-001"
    phone: "123456789"
    email: "kontakt@edk.org.pl"
```

## 🧪 Testy Sandbox

### Test 1: Utworzenie przesyłki

#### Przygotowanie danych testowych

```ruby
# Rails console
rails c

# Utwórz testową edycję
edition = Edition.create!(
  year: 2026,
  name: "EDK 2026 - TEST",
  price_per_unit: 12.00,
  active: true
)

# Utwórz inventory
inventory = Inventory.create!(
  edition: edition,
  available: 100,
  reserved: 0,
  shipped: 0
)

# Utwórz testowego użytkownika (lidera)
user = User.create!(
  email: "test.leader@example.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  first_name: "Jan",
  last_name: "Testowy",
  phone: "123456789",
  role: :leader
)

# Utwórz testowe zamówienie
order = Order.create!(
  user: user,
  edition: edition,
  quantity: 10,
  locker_code: "KRA010M",  # Testowy paczkomat InPost w Krakowie
  locker_address: "ul. Pawia 5",
  locker_city: "Kraków",
  locker_post_code: "31-154",
  status: :confirmed
)

# Utwórz shipment (tylko dla InPost Paczkomat)
shipment = Shipment.create!(
  order: order,
  status: "pending"
)
```

#### Wykonanie testu

```ruby
# Wywołaj job do utworzenia przesyłki
Apaczka::CreateShipmentJob.perform_now(shipment)

# Sprawdź rezultat
shipment.reload
puts "Status: #{shipment.status}"
puts "aPaczka Order ID: #{shipment.apaczka_order_id}"
puts "Waybill Number: #{shipment.waybill_number}"
puts "Tracking URL: #{shipment.tracking_url}"
puts "Label PDF present: #{shipment.label_pdf.present?}"
```

**Oczekiwany rezultat:**
- ✅ `shipment.status` = "label_printed"
- ✅ `shipment.apaczka_order_id` jest wypełnione
- ✅ `shipment.waybill_number` jest wypełnione
- ✅ `shipment.tracking_url` jest wypełnione
- ✅ `shipment.label_pdf` zawiera dane PDF (Binary)

---

### Test 2: Pobranie etykiety PDF

```ruby
# Pobierz shipment z poprzedniego testu
shipment = Shipment.last

# Sprawdź czy etykieta PDF istnieje
if shipment.label_pdf.present?
  # Zapisz do pliku (opcjonalnie)
  File.open("/tmp/apaczka_label_#{shipment.id}.pdf", "wb") do |file|
    file.write(shipment.label_pdf)
  end

  puts "✅ Etykieta PDF zapisana do /tmp/apaczka_label_#{shipment.id}.pdf"
  puts "Rozmiar pliku: #{shipment.label_pdf.bytesize} bajtów"
else
  puts "❌ Brak etykiety PDF"
end

# Alternatywnie: pobierz ponownie przez API
client = Apaczka::Client.new
label_pdf = client.get_waybill(shipment.apaczka_order_id)

if label_pdf
  File.open("/tmp/apaczka_label_direct_#{shipment.id}.pdf", "wb") do |file|
    file.write(label_pdf)
  end
  puts "✅ Etykieta pobrana ponownie z API"
else
  puts "❌ Nie udało się pobrać etykiety z API"
end
```

**Oczekiwany rezultat:**
- ✅ Plik PDF jest poprawny (można go otworzyć)
- ✅ Etykieta zawiera:
  - Kod paczkomatu (KRA010M)
  - Kod kreskowy
  - Adres nadawcy
  - Adres odbiorcy

**Weryfikacja PDF:**
```bash
# Otwórz plik PDF
open /tmp/apaczka_label_*.pdf  # macOS
xdg-open /tmp/apaczka_label_*.pdf  # Linux
```

---

### Test 3: Sprawdzenie statusu przesyłki

```ruby
# Sprawdź status przesyłki przez API
shipment = Shipment.last
client = Apaczka::Client.new

apaczka_status = client.get_order_status(shipment.apaczka_order_id)
puts "Status aPaczka: #{apaczka_status}"

# Uruchom job synchronizacji statusu
Apaczka::SyncStatusJob.perform_now

# Sprawdź zaktualizowany status
shipment.reload
puts "Aktualny status w systemie: #{shipment.status}"
```

**Możliwe statusy aPaczka:**
- `READY_TO_SHIP` → mapuje się na `label_printed`
- `PICKED_UP` → mapuje się na `in_transit`
- `IN_TRANSIT` → mapuje się na `in_transit`
- `DELIVERED` → mapuje się na `delivered`
- `READY_TO_PICKUP` → mapuje się na `delivered` (dla paczkomatów)
- `RETURNED` → mapuje się na `failed`

**Oczekiwany rezultat:**
- ✅ API zwraca status przesyłki
- ✅ Status jest poprawnie mapowany do wewnętrznych statusów
- ✅ `SyncStatusJob` aktualizuje status w bazie danych

---

### Test 4: Powiadomienia Email

#### Przygotowanie

Upewnij się że masz skonfigurowany mailer (np. letter_opener w development):

```ruby
# config/environments/development.rb powinien zawierać:
config.action_mailer.delivery_method = :letter_opener
config.action_mailer.perform_deliveries = true
```

#### Test email po wysyłce

```ruby
# Utwórz nowy shipment i wywołaj job
shipment = Shipment.last
Apaczka::CreateShipmentJob.perform_now(shipment)

# Email powinien zostać wysłany automatycznie
# W development - sprawdź /tmp/letter_opener/ lub localhost:3000/letter_opener
```

#### Test email po dostawie

```ruby
# Symuluj dostawę
shipment = Shipment.last
shipment.update!(
  status: "in_transit",
  delivered_at: nil
)

# Ręcznie wywołaj mailer dostawy
ShipmentMailer.delivered(shipment).deliver_now

# LUB zmień status przez SyncStatusJob
# (w prawdziwym scenariuszu, status zmienia się automatycznie gdy aPaczka potwierdzi dostawę)
```

**Oczekiwany rezultat:**
- ✅ Email **shipped** jest wysyłany po utworzeniu przesyłki
  - Zawiera numer śledzenia
  - Zawiera link do śledzenia
  - Prawidłowy odbiorca (darczyńca lub lider)
  - Nadawca: pakiety@edk.org.pl

- ✅ Email **delivered** jest wysyłany po dostawie
  - Zawiera informację o paczkomacie
  - Zawiera datę dostawy
  - Przypomina o 48h terminie odbioru

---

## 🔍 Debugging

### Sprawdzenie żądań HTTP

```ruby
# Włącz logging Faraday
Faraday.new do |faraday|
  faraday.response :logger, Rails.logger, bodies: true
end

# Wywołaj endpoint
client = Apaczka::Client.new
result = client.create_shipment(order)
```

### Sprawdzenie signature

```ruby
client = Apaczka::Client.new

# Testowe dane
endpoint = "/order_send/"
data = { test: "data" }.to_json
expires = 30.minutes.from_now.to_i

# Wygeneruj signature
signature = client.send(:generate_signature, endpoint, data, expires)

puts "App ID: #{ENV['APACZKA_APP_ID']}"
puts "Endpoint: #{endpoint}"
puts "Data: #{data}"
puts "Expires: #{expires}"
puts "Signature: #{signature}"
```

### Sprawdzenie odpowiedzi API

```ruby
client = Apaczka::Client.new

# Pobierz strukturę serwisów
response = client.send(:get, "/service_structure/")
puts JSON.pretty_generate(response)

# Znajdź INPOST_COURIER_POINT
services = response["response"] || []
inpost_service = services.find { |s| s["id"] == "INPOST_COURIER_POINT" }
puts "InPost service found: #{inpost_service.present?}"
```

---

## ✅ Checklist weryfikacji

Po zakończeniu wszystkich testów, upewnij się że:

- [ ] Przesyłka jest tworzona w sandbox aPaczka
- [ ] Otrzymujesz `order_id`, `waybill_number`, `tracking_url`
- [ ] Etykieta PDF jest pobierana i zawiera prawidłowe dane
- [ ] Status przesyłki aktualizuje się poprawnie
- [ ] Email "shipped" jest wysyłany po utworzeniu przesyłki
- [ ] Email "delivered" jest wysyłany po dostawie
- [ ] Magazyn jest aktualizowany (shipped count zwiększa się)
- [ ] Zamówienie/darowizna zmienia status na "shipped"
- [ ] Błędy API są logowane i obsługiwane prawidłowo

---

## 📞 Kontakt z supportem aPaczka

Jeśli napotkasz problemy:

- **Email:** support@apaczka.pl
- **Telefon:** +48 61 657 57 77
- **Panel:** https://panel.apaczka.pl
- **Dokumentacja:** https://panel.apaczka.pl/dokumentacja_api_v2.php

---

## 🚀 Następne kroki

Po pozytywnych testach sandbox:

1. Uzyskaj **produkcyjne credentials** od aPaczka
2. Zaktualizuj konfigurację na produkcji
3. Ustaw `APACZKA_SANDBOX=false`
4. Przetestuj na niewielkiej liczbie rzeczywistych przesyłek
5. Monitoruj logi i statusy pierwszych 10-20 przesyłek
