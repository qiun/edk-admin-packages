# Redesign systemu statusów — Plan implementacji

## Przegląd

System statusów dla wysyłek, płatności cegiełek i zamówień liderów jest niespójny i nieczytelny. Statusy nie odzwierciedlają rzeczywistego stanu przesyłek z aPaczka ani płatności z Przelewy24. Brakuje automatycznej synchronizacji z aPaczka.

**Wzór**: PrestaShop / WooCommerce — sprawdzony system statusów e-commerce.

## Analiza obecnego stanu (dane z bazy produkcyjnej)

### Cegiełki (Donation) — 69 rekordów
| Status | Ilość | Problem |
|--------|-------|---------|
| pending | 7 | Porzucone koszyki — ktoś zaczął ale nie zapłacił. Mieszają się z nowymi |
| paid | 39 | OK |
| failed | 3 | OK |
| refunded | 20 | OK |

### Wysyłki (Shipment) — 69 rekordów
| Status | Ilość | Problem |
|--------|-------|---------|
| shipped | 47 | **WSZYSTKIE** mają status "shipped" — żadna nie jest "delivered" mimo że część pewnie już dotarła! Brak synchronizacji |
| failed | 22 | Wczesne błędy (z okresu testów aPaczka) — 19 bez `apaczka_order_id` |

### Zamówienia (Order) — 32 rekordy
| Status | Ilość | Problem |
|--------|-------|---------|
| pending | 13 | OK — czekają na potwierdzenie admina |
| confirmed | 7 | **6 z nich ma wysyłkę "shipped"** ale zamówienie nadal "confirmed" — niespójność! |
| shipped | 2 | Tylko 2 poprawnie zsynchronizowane |
| cancelled | 10 | OK |

### Kluczowe problemy:
1. **Zero synchronizacji z aPaczka** — `SyncStatusJob` istnieje ale NIE jest zaplanowany w `recurring.yml`
2. **Niespójność Order ↔ Shipment** — zamówienie "confirmed" ale wysyłka "shipped"
3. **Brak granularnych statusów wysyłki** — nie wiadomo czy kurier odebrał, jest w drodze, czy czeka w Paczkomacie
4. **Porzucone cegiełki** mieszają się z nowymi w zakładce "Oczekujące"

## Czego NIE robimy

- Nie zmieniamy integracji z Przelewy24 (webhook działa poprawnie)
- Nie zmieniamy logiki tworzenia wysyłek w aPaczka
- Nie dodajemy webhooków z aPaczka (ich Push API wymaga osobnej konfiguracji z supportem)
- Nie zmieniamy statusów dla zwrotów (Return) ani rozliczeń (Settlement)

---

## Nowy system statusów

### 1. Wysyłki (Shipment) — wzór PrestaShop

Obecne 4 statusy → **8 statusów** mapowanych z aPaczka API:

| Status | Polski | Kiedy ustawiany | Kolor badge |
|--------|--------|-----------------|-------------|
| `pending` | Oczekuje na etykietę | Shipment utworzony, czeka na aPaczka | yellow |
| `label_ready` | Etykieta gotowa | aPaczka wygenerowała etykietę (odpowiedź z API) | blue |
| `picked_up` | Odebrana przez kuriera | aPaczka status: POSTED | indigo |
| `in_transit` | W drodze | aPaczka status: ON_THE_WAY | indigo |
| `ready_for_pickup` | Gotowa do odbioru | aPaczka status: READY_TO_PICKUP (Paczkomat) | green |
| `delivered` | Dostarczona | aPaczka status: DELIVERED | green |
| `returned` | Zwrot do nadawcy | aPaczka status: RETURNED / OTHER | red |
| `failed` | Błąd | Błąd tworzenia w aPaczka | red |

**Mapowanie statusów aPaczka → nasze:**

```ruby
APACZKA_STATUS_MAP = {
  "NEW"              => "label_ready",
  "READY_TO_SEND"    => "label_ready",
  "READY_TO_PICKUP"  => "ready_for_pickup",  # Paczkomat — czeka na odbiór
  "ADVISING"         => "label_ready",
  "POSTED"           => "picked_up",
  "ON_THE_WAY"       => "in_transit",
  "OUT_FOR_DELIVERY" => "in_transit",
  "DELIVERED"        => "delivered",
  "AVIZO"            => "in_transit",         # Awizo — ponowna próba doręczenia
  "OTHER"            => "returned",
  "RETURNED"         => "returned",
  "CANCELLED"        => "failed",
  "FAILED"           => "failed"
}.freeze
```

**Zmiana w `CreateShipmentJob`**: Po sukcesie ustawiamy `label_ready` zamiast `shipped` (bo kurier jeszcze nie odebrał).

### 2. Cegiełki (Donation `payment_status`) — bez zmian + abandoned

Obecne statusy + nowy `abandoned`:

| Status | Polski | Kiedy | Kolor badge |
|--------|--------|-------|-------------|
| `pending` | Oczekuje na płatność | Darczyńca złożył formularz | yellow |
| `paid` | Opłacone | Przelewy24 potwierdził | green |
| `failed` | Płatność nieudana | Błąd Przelewy24 | red |
| `refunded` | Zwrócone | Admin anulował | gray |
| `abandoned` | Porzucone | Auto: 24h bez płatności | gray |

**Logika abandoned**: Cron job co godzinę → cegiełki `pending` starsze niż 24h → `abandoned`. Zwalnia zarezerwowany inwentarz.

### 3. Zamówienia liderów (Order `status`) — auto-sync z wysyłką

Obecne statusy OK, ale dodajemy automatyczną synchronizację:

| Status | Polski | Kiedy |
|--------|--------|-------|
| `pending` | Oczekuje | Lider złożył zamówienie |
| `confirmed` | Potwierdzone | Admin potwierdził |
| `shipped` | W realizacji | Wysyłka ma status ≥ `label_ready` |
| `delivered` | Dostarczone | Wysyłka `delivered` |
| `cancelled` | Anulowane | Admin/lider anulował |

**Automatyczna synchronizacja**: Gdy `SyncStatusJob` aktualizuje Shipment, automatycznie aktualizuje też Order:
- Shipment `label_ready`/`picked_up`/`in_transit`/`ready_for_pickup` → Order `shipped`
- Shipment `delivered` → Order `delivered`

---

## Fazy implementacji

### Faza 1: Migracja statusów wysyłek + automatyczna synchronizacja

**Cel**: Rozszerzyć statusy Shipment z 4 do 8 i uruchomić automatyczną synchronizację z aPaczka.

#### 1.1 Migracja bazy danych

**Plik**: Nowa migracja `db/migrate/XXXX_expand_shipment_statuses.rb`

```ruby
class ExpandShipmentStatuses < ActiveRecord::Migration[8.0]
  def up
    # Istniejące shipped → label_ready (bo nie wiemy czy kurier odebrał)
    Shipment.where(status: "shipped").update_all(status: "label_ready")

    # Zsynchronizuj zamówienia z wysyłkami
    Order.where(status: "confirmed").joins(:shipment).where(shipments: { status: "label_ready" }).update_all(status: "shipped")
  end

  def down
    Shipment.where(status: %w[label_ready picked_up in_transit ready_for_pickup]).update_all(status: "shipped")
    Shipment.where(status: "returned").update_all(status: "failed")
  end
end
```

#### 1.2 Model Shipment

**Plik**: `app/models/shipment.rb`

Zmiana enum:
```ruby
enum :status, {
  pending: "pending",
  label_ready: "label_ready",
  picked_up: "picked_up",
  in_transit: "in_transit",
  ready_for_pickup: "ready_for_pickup",
  delivered: "delivered",
  returned: "returned",
  failed: "failed"
}
```

Dodanie scope'ów:
```ruby
scope :active, -> { where(status: %w[label_ready picked_up in_transit ready_for_pickup]) }
scope :trackable, -> { where.not(apaczka_order_id: nil).where(status: %w[label_ready picked_up in_transit ready_for_pickup]) }
```

#### 1.3 Job: CreateShipmentJob

**Plik**: `app/jobs/apaczka/create_shipment_job.rb`

Zmiana: po sukcesie ustawiamy `label_ready` zamiast `shipped`:
```ruby
# Linia 31 zmiana:
status: "label_ready"   # było: "shipped"
```

#### 1.4 Job: SyncStatusJob (przepisany)

**Plik**: `app/jobs/apaczka/sync_status_job.rb`

```ruby
module Apaczka
  class SyncStatusJob < ApplicationJob
    queue_as :low

    APACZKA_STATUS_MAP = {
      "NEW"              => "label_ready",
      "READY_TO_SEND"    => "label_ready",
      "READY_TO_PICKUP"  => "ready_for_pickup",
      "ADVISING"         => "label_ready",
      "POSTED"           => "picked_up",
      "ON_THE_WAY"       => "in_transit",
      "OUT_FOR_DELIVERY" => "in_transit",
      "DELIVERED"        => "delivered",
      "AVIZO"            => "in_transit",
      "OTHER"            => "returned",
      "RETURNED"         => "returned",
      "CANCELLED"        => "failed",
      "FAILED"           => "failed"
    }.freeze

    # Statusy z których synchronizujemy (aktywne wysyłki)
    TRACKABLE_STATUSES = %w[label_ready picked_up in_transit ready_for_pickup].freeze

    def perform
      client = ::Apaczka::Client.new

      Shipment.where(status: TRACKABLE_STATUSES)
              .where.not(apaczka_order_id: nil)
              .find_each do |shipment|
        sync_shipment(client, shipment)
      rescue => e
        Rails.logger.error("Sync failed for shipment ##{shipment.id}: #{e.message}")
      end
    end

    private

    def sync_shipment(client, shipment)
      apaczka_status = client.get_order_status(shipment.apaczka_order_id)
      return unless apaczka_status.present?

      new_status = APACZKA_STATUS_MAP[apaczka_status.to_s.upcase] || shipment.status
      return if shipment.status == new_status

      Rails.logger.info "Shipment ##{shipment.id}: #{shipment.status} → #{new_status} (aPaczka: #{apaczka_status})"

      shipment.update!(status: new_status)

      case new_status
      when "delivered"
        shipment.update!(delivered_at: Time.current)
        sync_source_status(shipment, :delivered)
        ShipmentMailer.delivered(shipment).deliver_later
      when "picked_up", "in_transit", "ready_for_pickup"
        sync_source_status(shipment, :shipped)
      when "returned"
        sync_source_status(shipment, :shipped) # zamówienie nadal "w realizacji"
      end
    end

    def sync_source_status(shipment, target_status)
      source = shipment.source
      return unless source.is_a?(Order)

      case target_status
      when :delivered
        source.update!(status: :delivered) unless source.delivered? || source.cancelled?
      when :shipped
        source.update!(status: :shipped) unless source.shipped? || source.delivered? || source.cancelled?
      end
    end
  end
end
```

#### 1.5 Zaplanowanie crona

**Plik**: `config/recurring.yml`

```yaml
production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12

  sync_apaczka_statuses:
    class: Apaczka::SyncStatusJob
    queue: low
    schedule: every 15 minutes
```

#### 1.6 Aktualizacja ApplicationHelper — badge'e

**Plik**: `app/helpers/application_helper.rb`

Dodanie nowych statusów do `status_badge`:
```ruby
# colors:
label_ready: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
picked_up: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400",
in_transit: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/30 dark:text-indigo-400",
ready_for_pickup: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
returned: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400",
abandoned: "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400",

# translations:
label_ready: "Etykieta gotowa",
picked_up: "Odebrana przez kuriera",
in_transit: "W drodze",
ready_for_pickup: "Gotowa do odbioru",
returned: "Zwrot",
abandoned: "Porzucone",
```

#### 1.7 Aktualizacja widoków — filtry i tabelki

**Pliki do aktualizacji:**

1. `app/views/admin/shipments/index.html.erb` — nowe filtry:
   - Oczekujące (pending)
   - Etykieta gotowa (label_ready)
   - W realizacji (picked_up + in_transit + ready_for_pickup) — grupowo
   - Dostarczone (delivered)
   - Zwroty (returned)
   - Błędy (failed)
   - Wszystkie (all)

2. `app/views/admin/donations/index.html.erb` — dodanie zakładki "Porzucone"

3. `app/views/warehouse/donation_shipments/index.html.erb` — nowe filtry
4. `app/views/warehouse/leader_shipments/index.html.erb` — nowe filtry
5. `app/views/warehouse/donation_shipments/_shipment_row.html.erb` — waybill link warunek
6. `app/views/warehouse/leader_shipments/_shipment_row.html.erb` — waybill link warunek
7. `app/views/warehouse/shipments/index.html.erb` — nowe status hashes
8. `app/views/warehouse/shipments/show.html.erb` — nowe status hashes

#### 1.8 Aktualizacja kontrolerów

**Pliki:**

1. `app/controllers/admin/shipments_controller.rb`:
   - Zmiana `map_apaczka_status` na użycie `APACZKA_STATUS_MAP` z SyncStatusJob
   - Default filter: `label_ready` zamiast `pending` (etykiety gotowe do wysłania)

2. `app/controllers/admin/donations_controller.rb`:
   - Default filter uwzględnia `abandoned`

3. `app/controllers/warehouse/donation_shipments_controller.rb`:
   - Aktualizacja filtrów
   - `mark_shipped` ustawia `picked_up` zamiast `shipped`

4. `app/controllers/warehouse/leader_shipments_controller.rb`:
   - Analogiczne zmiany

5. `app/controllers/concerns/retry_shipment_handler.rb`:
   - `CANCELLED_STATUSES` — bez zmian (already correct)
   - `reset_and_retry_shipment` — bez zmian (resets to pending)

6. `app/controllers/leader/sales_reports_controller.rb`:
   - Zmiana query z `[:shipped, :delivered]` na `[:label_ready, :picked_up, :in_transit, :ready_for_pickup, :delivered]`

7. `app/controllers/leader/returns_controller.rb`:
   - Analogiczna zmiana

#### 1.9 Admin donations show — warunek wyświetlania button "Oznacz jako wysłaną"

**Plik**: `app/views/admin/donations/show.html.erb`

Zmiana warunku z `shipment.status == "pending"` na `shipment.pending?` (bez zmian logicznych).

### Weryfikacja Fazy 1:

#### Automatyczna:
- [ ] Migracja działa: `bin/rails db:migrate`
- [ ] Brak błędów: `bin/rails runner "Shipment.first"`
- [ ] Enum poprawny: `bin/rails runner "puts Shipment.statuses.keys"`

#### Manualna:
- [ ] `/admin/shipments` — nowe filtry działają
- [ ] `/admin/donations` — zakładki z nowymi statusami
- [ ] `Apaczka::SyncStatusJob.perform_now` — synchronizuje statusy
- [ ] Warehouse panel — nowe filtry
- [ ] Przejrzenie danych — istniejące "shipped" zmigrowały na "label_ready"

---

### Faza 2: Auto-abandonment porzuconych cegiełek

**Cel**: Cegiełki bez płatności po 24h automatycznie oznaczane jako "abandoned".

#### 2.1 Migracja — nowy status

**Plik**: Nowa migracja `db/migrate/XXXX_add_abandoned_donation_status.rb`

```ruby
class AddAbandonedDonationStatus < ActiveRecord::Migration[8.0]
  def up
    # Oznacz stare pending jako abandoned (starsze niż 24h)
    Donation.where(payment_status: "pending")
            .where("created_at < ?", 24.hours.ago)
            .update_all(payment_status: "abandoned")
  end

  def down
    Donation.where(payment_status: "abandoned").update_all(payment_status: "pending")
  end
end
```

#### 2.2 Model Donation

**Plik**: `app/models/donation.rb`

Dodanie `abandoned` do enum:
```ruby
enum :payment_status, {
  pending: "pending",
  paid: "paid",
  failed: "failed",
  refunded: "refunded",
  abandoned: "abandoned"
}, prefix: :payment
```

#### 2.3 Job: AbandonExpiredDonationsJob

**Plik**: `app/jobs/abandon_expired_donations_job.rb`

```ruby
class AbandonExpiredDonationsJob < ApplicationJob
  queue_as :low

  EXPIRY_HOURS = 24

  def perform
    expired = Donation.where(payment_status: "pending")
                      .where("created_at < ?", EXPIRY_HOURS.hours.ago)

    count = expired.count
    return if count.zero?

    expired.find_each do |donation|
      donation.update!(payment_status: :abandoned)

      # Zwolnij zarezerwowany inwentarz jeśli gift
      if donation.want_gift? && donation.edition&.inventory
        begin
          donation.edition.inventory.release_reservation(donation.quantity)
        rescue => e
          Rails.logger.error "Failed to release inventory for donation ##{donation.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info "Abandoned #{count} expired donations"
  end
end
```

#### 2.4 Zaplanowanie crona

**Plik**: `config/recurring.yml` — dodanie:

```yaml
  abandon_expired_donations:
    class: AbandonExpiredDonationsJob
    queue: low
    schedule: every hour at minute 30
```

#### 2.5 Aktualizacja widoków

**Plik**: `app/views/admin/donations/index.html.erb`

Dodanie zakładki "Porzucone" (abandoned) + zmiana default filter.

### Weryfikacja Fazy 2:

#### Automatyczna:
- [ ] Migracja: `bin/rails db:migrate`
- [ ] Enum: `bin/rails runner "puts Donation.payment_statuses.keys"`
- [ ] Job: `bin/rails runner "AbandonExpiredDonationsJob.perform_now"`

#### Manualna:
- [ ] `/admin/donations` — zakładka "Porzucone" pokazuje stare pending
- [ ] Nowe pending (< 24h) nadal w "Oczekujące"
- [ ] Po 24h bez płatności → auto-przejście do "Porzucone"

---

### Faza 3: Synchronizacja Order ↔ Shipment + odświeżenie statusów bieżących

**Cel**: Naprawić niespójności między zamówieniami a wysyłkami. Ręczne odświeżenie statusów z aPaczka.

#### 3.1 Migracja — naprawa niespójności

**Plik**: Nowa migracja `db/migrate/XXXX_fix_order_shipment_status_consistency.rb`

```ruby
class FixOrderShipmentStatusConsistency < ActiveRecord::Migration[8.0]
  def up
    # Zamówienia "confirmed" z wysyłką aktywną → "shipped"
    Order.where(status: "confirmed")
         .joins(:shipment)
         .where(shipments: { status: %w[label_ready picked_up in_transit ready_for_pickup] })
         .update_all(status: "shipped")

    # Zamówienia "confirmed" z wysyłką delivered → "delivered"
    Order.where(status: "confirmed")
         .joins(:shipment)
         .where(shipments: { status: "delivered" })
         .update_all(status: "delivered")
  end

  def down
    # Cannot reliably reverse
  end
end
```

#### 3.2 Rake task — jednorazowe odświeżenie z aPaczka

**Plik**: `lib/tasks/sync_all_statuses.rake`

```ruby
namespace :apaczka do
  desc "One-time full sync of all shipment statuses from aPaczka"
  task sync_all: :environment do
    client = Apaczka::Client.new

    shipments = Shipment.where.not(apaczka_order_id: nil)
                        .where.not(status: %w[delivered failed returned])

    puts "Syncing #{shipments.count} shipments..."

    shipments.find_each do |shipment|
      apaczka_status = client.get_order_status(shipment.apaczka_order_id)
      next unless apaczka_status.present?

      new_status = Apaczka::SyncStatusJob::APACZKA_STATUS_MAP[apaczka_status.to_s.upcase]
      next unless new_status && shipment.status != new_status

      old = shipment.status
      shipment.update!(status: new_status)
      shipment.update!(delivered_at: Time.current) if new_status == "delivered"

      puts "  Shipment ##{shipment.id}: #{old} → #{new_status} (aPaczka: #{apaczka_status})"
    rescue => e
      puts "  ERROR Shipment ##{shipment.id}: #{e.message}"
    end

    puts "Done!"
  end
end
```

### Weryfikacja Fazy 3:

#### Automatyczna:
- [ ] Migracja: `bin/rails db:migrate`
- [ ] Rake: `bin/rails apaczka:sync_all`

#### Manualna:
- [ ] `/admin/orders` — zamówienia z wysyłkami mają poprawny status
- [ ] Brak "confirmed" zamówień z aktywną wysyłką
- [ ] Po rake task — wysyłki mają aktualne statusy z aPaczka

---

## Podsumowanie zmian

### Pliki do zmodyfikowania:
1. `app/models/shipment.rb` — nowy enum (8 statusów)
2. `app/models/donation.rb` — dodanie `abandoned`
3. `app/jobs/apaczka/create_shipment_job.rb` — `shipped` → `label_ready`
4. `app/jobs/apaczka/sync_status_job.rb` — przepisany z nowym mapowaniem
5. `app/helpers/application_helper.rb` — nowe badge'e i tłumaczenia
6. `app/controllers/admin/shipments_controller.rb` — nowe filtry + mapowanie
7. `app/controllers/admin/donations_controller.rb` — filtr abandoned
8. `app/controllers/warehouse/donation_shipments_controller.rb` — nowe statusy
9. `app/controllers/warehouse/leader_shipments_controller.rb` — nowe statusy
10. `app/controllers/leader/sales_reports_controller.rb` — query update
11. `app/controllers/leader/returns_controller.rb` — query update
12. `config/recurring.yml` — 2 nowe cron joby
13. Wszystkie widoki z filtrami/badge'ami statusów (8 plików)

### Nowe pliki:
1. `db/migrate/XXXX_expand_shipment_statuses.rb`
2. `db/migrate/XXXX_add_abandoned_donation_status.rb`
3. `db/migrate/XXXX_fix_order_shipment_status_consistency.rb`
4. `app/jobs/abandon_expired_donations_job.rb`
5. `lib/tasks/sync_all_statuses.rake`

### Migracja danych:
- `shipped` → `label_ready` (47 shipments)
- Stare `pending` donations (> 24h) → `abandoned` (stare 7 pending)
- Order `confirmed` z aktywną wysyłką → `shipped` (6 orders)

### Cron joby:
- `Apaczka::SyncStatusJob` — co 15 minut
- `AbandonExpiredDonationsJob` — co godzinę
