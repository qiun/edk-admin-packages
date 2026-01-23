# Email System - Zunifikowana Komunikacja

## Przegląd

System emailowy używa jednego adresu nadawcy dla wszystkich typów komunikacji (darowizny indywidualne i zamówienia liderów okręgowych).

## Adres Email

### **pakiety@edk.org.pl** - Wszystkie Komunikaty
Używany dla wszystkich emaili w systemie:
- **Darowizny indywidualne:**
  - Potwierdzenia płatności
  - Powiadomienia o wysyłce upominków
  - Potwierdzenia dostawy
- **Liderzy okręgowi:**
  - Potwierdzenia zamówień
  - Zmiany statusu zamówień
  - Powiadomienia o wysyłkach
  - Przypomnienia o rozliczeniach
  - Emaile powitalne dla nowych kont

**Zmienna środowiskowa:** `LEADER_EMAIL_FROM`

## Mailery

### DonationMailer (`pakiety@edk.org.pl`)
```ruby
class DonationMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  def confirmation(donation)     # Potwierdzenie płatności
  def shipment_sent(donation, tracking_number)  # Wysłano upominek
end
```

**Metody:**
- `confirmation(donation)` - Potwierdzenie płatności za darowiznę
- `shipment_sent(donation, tracking_number)` - Powiadomienie o wysłaniu upominku

### OrderMailer (`pakiety@edk.org.pl`)
```ruby
class OrderMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  def confirmed(order)           # Potwierdzenie zamówienia lidera
  def new_order_notification(order)  # Powiadomienie admina o nowym zamówieniu
  def status_changed(order, old_status, new_status)  # Zmiana statusu
end
```

**Metody:**
- `confirmed(order)` - Potwierdzenie zamówienia dla lidera
- `new_order_notification(order)` - Powiadomienie adminów o nowym zamówieniu
- `status_changed(order, old_status, new_status)` - Powiadomienie o zmianie statusu zamówienia

### ShipmentMailer (`pakiety@edk.org.pl`)
```ruby
class ShipmentMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  def shipped(shipment)          # Paczka wysłana
  def delivered(shipment)        # Paczka dostarczona
end
```

**Logika wyboru odbiorcy:**
- Jeśli `shipment.source` to `Donation` → email do darczyńcy
- Jeśli `shipment.source` to `Order` → email do lidera

**Metody:**
- `shipped(shipment)` - Powiadomienie o wysyłce paczki
- `delivered(shipment)` - Powiadomienie o dostarczeniu paczki

### UserMailer (`pakiety@edk.org.pl`)
```ruby
class UserMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  def welcome(user, password = nil)     # Email powitalny
  def password_reset(user, reset_url)   # Reset hasła
end
```

**Metody:**
- `welcome(user, password)` - Email powitalny dla nowego konta lidera
- `password_reset(user, reset_url)` - Instrukcje resetowania hasła

### SettlementMailer (`pakiety@edk.org.pl`)
```ruby
class SettlementMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  def reminder(settlement)       # Przypomnienie o rozliczeniu
  def confirmed(settlement)      # Potwierdzenie rozliczenia
  def summary(settlement)        # Podsumowanie rozliczenia
end
```

**Metody:**
- `reminder(settlement)` - Przypomnienie o zaległej płatności
- `confirmed(settlement)` - Potwierdzenie rozliczenia
- `summary(settlement)` - Podsumowanie rozliczenia za edycję

### AdminMailer (`pakiety@edk.org.pl`)
```ruby
class AdminMailer < ApplicationMailer
  default from: "pakiety@edk.org.pl"

  def low_stock_alert(edition:, available:, admin_emails:)   # Alert o niskim stanie
  def out_of_stock_alert(edition:, admin_emails:)            # Alert o braku pakietów
end
```

**Metody:**
- `low_stock_alert` - Powiadomienie o niskim stanie magazynowym
- `out_of_stock_alert` - Powiadomienie o braku pakietów w magazynie

## Konfiguracja

### Zmienne Środowiskowe

#### Development (.env)
```bash
LEADER_EMAIL_FROM=pakiety@edk.org.pl
```

#### Production (Kubernetes ConfigMap)
```yaml
data:
  LEADER_EMAIL_FROM: "pakiety@edk.org.pl"
```

## Przykłady Użycia

### Darowizna - Potwierdzenie Płatności
```ruby
# W webhooks_controller.rb po potwierdzeniu płatności
DonationMailer.confirmation(@donation).deliver_later
```

### Zamówienie Lidera - Potwierdzenie
```ruby
# W orders_controller.rb po utworzeniu zamówienia
OrderMailer.confirmed(@order).deliver_later
```

### Wysyłka - Wysyłka Powiadomienia
```ruby
# W CreateShipmentJob po utworzeniu wysyłki
ShipmentMailer.shipped(shipment).deliver_later
# Użyje pakiety@ jako nadawcy, wybierze odpowiedniego odbiorcę
```

### Nowe Konto Lidera
```ruby
# W admin/users_controller.rb po utworzeniu konta
UserMailer.welcome(user, temporary_password).deliver_later
```

### Przypomnienie o Rozliczeniu
```ruby
# W settlement reminder job
SettlementMailer.reminder(settlement).deliver_later
```

## Testowanie

### Sprawdzenie Konfiguracji
```bash
# Rails console
DonationMailer.default[:from]    # => "pakiety@edk.org.pl"
OrderMailer.default[:from]       # => "pakiety@edk.org.pl"
UserMailer.default[:from]        # => "pakiety@edk.org.pl"
SettlementMailer.default[:from]  # => "pakiety@edk.org.pl"
ShipmentMailer.default[:from]    # => "pakiety@edk.org.pl"
```

### Test Wysyłki
```bash
# Development - używa letter_opener (otwiera email w przeglądarce)
DonationMailer.confirmation(Donation.last).deliver_now

# Sprawdzenie wyboru odbiorcy w ShipmentMailer
shipment_for_donation = Shipment.where(source_type: 'Donation').last
ShipmentMailer.shipped(shipment_for_donation).deliver_now
# Powinien wysłać do darczyńcy z nadawcą pakiety@edk.org.pl

shipment_for_order = Shipment.where(source_type: 'Order').last
ShipmentMailer.shipped(shipment_for_order).deliver_now
# Powinien wysłać do lidera z nadawcą pakiety@edk.org.pl
```

## Szablony Email

Wszystkie mailery mają odpowiednie szablony HTML i TEXT:

### DonationMailer
- `app/views/donation_mailer/confirmation.html.erb`
- `app/views/donation_mailer/confirmation.text.erb`
- `app/views/donation_mailer/shipment_sent.html.erb`
- `app/views/donation_mailer/shipment_sent.text.erb`

### OrderMailer
- `app/views/order_mailer/confirmed.html.erb`
- `app/views/order_mailer/confirmed.text.erb`
- `app/views/order_mailer/new_order_notification.html.erb`

### ShipmentMailer
- `app/views/shipment_mailer/shipped.html.erb`
- `app/views/shipment_mailer/shipped.text.erb`
- `app/views/shipment_mailer/delivered.html.erb`

### UserMailer
- `app/views/user_mailer/welcome.html.erb`

### SettlementMailer
- `app/views/settlement_mailer/reminder.html.erb`

### AdminMailer
- `app/views/admin_mailer/low_stock_alert.html.erb`
- `app/views/admin_mailer/out_of_stock_alert.html.erb`

## Bezpieczeństwo

### Najlepsze Praktyki
1. **Zunifikowana komunikacja** - Jeden adres email dla wszystkich typów komunikacji upraszcza zarządzanie
2. **Profesjonalny wizerunek** - Adres pakiety@edk.org.pl reprezentuje cały system EDK Packages
3. **Automatyczny routing** - System automatycznie wybiera odpowiedniego odbiorcę na podstawie typu źródła

### Ochrona Przed Spamem
Wszystkie emaile używają:
- SPF record dla domeny edk.org.pl
- DKIM signing dla autentykacji
- DMARC policy dla ochrony przed phishingiem

## Monitoring

### Logi Email (Production)
```bash
# Kubernetes - sprawdzenie logów wysyłki email
kubectl logs -l app=edk-admin-packages | grep -i "mail"

# Rails console - sprawdzenie kolejki jobów
Sidekiq::Queue.new.size  # Jeśli używamy Sidekiq
```

### Metryki
- Liczba wysłanych emaili (darowizny vs zamówienia liderów)
- Bounce rate
- Open rate (jeśli używamy tracking)
- Delivery rate

## Troubleshooting

### Problem: Email nie wysyła się
```bash
# Sprawdź konfigurację SMTP
Rails.application.config.action_mailer.smtp_settings

# Sprawdź zmienne środowiskowe
ENV['LEADER_EMAIL_FROM']     # => "pakiety@edk.org.pl"

# Sprawdź kolejkę background jobs
Sidekiq::Queue.new('mailers').size
```

### Problem: Zły adres nadawcy
```bash
# Sprawdź w Rails console
mailer = DonationMailer.confirmation(Donation.last)
mailer.message[:from].to_s  # Powinno być "pakiety@edk.org.pl"
```

### Problem: Shipment wysyła do złego odbiorcy
```ruby
# Sprawdź typ źródła
shipment = Shipment.find(123)
shipment.source.class  # => Donation lub Order

# Test w konsoli
mailer = ShipmentMailer.shipped(shipment)
mailer.message[:from].to_s  # => "pakiety@edk.org.pl"
mailer.message[:to].to_s
# Donation => email darczyńcy
# Order => email lidera
```

## Przyszłe Rozszerzenia

### Planowane Funkcjonalności
1. **Email tracking** - śledzenie otwarć i kliknięć
2. **A/B testing** - testowanie różnych wersji szablonów
3. **Personalizacja** - dynamiczne treści na podstawie profilu użytkownika
4. **Automatyczne reminder** - przypomnienia o nieodebranych upominkach
5. **Email preferences** - preferencje częstotliwości powiadomień

## Kontakt

W razie pytań lub problemów:
- **Techniczne:** admin@edk.org.pl
- **Ogólne (darowizny i zamówienia):** pakiety@edk.org.pl
