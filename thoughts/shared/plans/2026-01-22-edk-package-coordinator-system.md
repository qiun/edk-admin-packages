# EDK Package Coordinator System - Plan Implementacji

## 📊 Status Implementacji (Aktualizacja: 2026-01-22)

| Faza | Nazwa | Status | Uwagi |
|------|-------|--------|-------|
| 1 | Fundament Projektu | ✅ DONE | Devise, TailAdmin, baza danych |
| 2 | Core Models i Logika Magazynowa | ✅ DONE | Modele, walidacje, relacje |
| 3 | Panel Koordynatora (Admin) | ✅ DONE | Dashboard, użytkownicy, edycje, magazyn |
| 4 | Integracja aPaczka.pl | 🔶 PARTIAL | Serwisy gotowe, testy sandbox do weryfikacji |
| 5 | Panel Lidera Okręgu | 🔶 PARTIAL | Kontrolery gotowe, widoki do dopracowania |
| 6 | Strona Publiczna (Cegiełki) | 🔶 PARTIAL | Formularz gotowy, Przelewy24 do integracji |
| 7 | System Rozliczeń | ✅ DONE | Serwis kalkulacji, testy przechodzą |
| 8 | Powiadomienia Email | 🔶 PARTIAL | Alerty magazynowe gotowe |
| 9 | Deploy z Kamal | ⏳ TODO | - |
| 10 | Testy i Dokumentacja | ⏳ TODO | - |

### Co działa:
- ✅ Logowanie/autoryzacja (Devise)
- ✅ Panel admina z TailAdmin
- ✅ Zarządzanie edycjami, użytkownikami, magazynem
- ✅ System powiadomień o stanie magazynowym
- ✅ Strona cegiełek z formularzem i mapą paczkomatów (InPost)
- ✅ Walidacja i rezerwacja magazynowa

### Do zrobienia:
- ⏳ Integracja płatności Przelewy24 (credentials w config/przelewy24_config.txt)
- ⏳ Testy sandbox aPaczka.pl
- ⏳ Deploy na produkcję

---

## Przegląd

System zarządzania pakietami EDK dla Koordynatora (Rafała Wojtkiewicza). Umożliwia kompleksowe zarządzanie dystrybucją pakietów EDK ("Niezbędnik Pątnika") do Liderów Okręgowych oraz darczyńców indywidualnych.

### Pakiet EDK zawiera:
- Książeczka z rozważaniami
- Opaska silikonowa z hasłem edycji ("Nie ma, że się nie da")
- Opaska odblaskowa

### Kluczowe funkcjonalności:
- **Panel Koordynatora**: Zarządzanie magazynem, zamówieniami, wysyłkami, rozliczeniami
- **Panel Lidera Okręgu**: Zamawianie pakietów, raportowanie sprzedaży, zwroty
- **Strona publiczna**: Cegiełki dla darczyńców indywidualnych (50 zł/pakiet)
- **Integracja aPaczka.pl**: Automatyczne nadawanie paczek InPost
- **System rozliczeń**: Model komisowy z indywidualnymi cenami

## Analiza Stanu Obecnego

### Słownik pojęć EDK (z e-DK Panel):
- **Edycja** - Cykliczne wydarzenie EDK (zwykle raz do roku przed Wielkanocą)
- **Okręg (Area Group)** - Grupa rejonów, zarządzana przez Lidera Okręgu
- **Rejon (Area)** - Podstawowa jednostka organizacyjna, powiązana z kościołem
- **Lider Okręgu (LO)** - Osoba koordynująca działania w rejonach
- **Lider Rejonu (LR)** - Osoba odpowiedzialna za organizację EDK w rejonie

### Obecny system cegiełek (edk-donations-refactor):
- Next.js 15 + React 19
- Przelewy24 (płatności)
- Mapa Furgonetka.pl (wybór paczkomatu InPost/ORLEN)
- Tailwind CSS

## Wymagania Funkcjonalne

### 1. Role użytkowników

| Rola | Uprawnienia |
|------|-------------|
| **Admin (Koordynator)** | Pełen dostęp: użytkownicy, magazyn, zamówienia, wysyłki, rozliczenia, ceny, edycje |
| **Pracownik Magazynu** | Podgląd zamówień, potwierdzanie wysyłek, aktualizacja stanów magazynowych |
| **Lider Okręgu** | Zamawianie pakietów, raportowanie sprzedaży, podgląd własnych rozliczeń, zwroty |

### 2. Funkcjonalności Koordynatora (Admin)

#### 2.1 Zarządzanie edycjami
- Tworzenie nowych edycji (np. EDK 2026, EDK 2027)
- Ustawianie aktywnej edycji
- Kopiowanie ustawień z poprzedniej edycji
- Blokowanie/odblokowywanie zamówień (globalnie lub per lider)

#### 2.2 Zarządzanie magazynem
- Stan magazynowy pakietów (dostępne, zarezerwowane, wysłane)
- Historia ruchów magazynowych
- Alertyi o niskim stanie
- Dashboard z pełnym obrazem sytuacji

#### 2.3 Zarządzanie cenami
- Cena globalna za pakiet (domyślna dla wszystkich liderów)
- Ceny indywidualne per lider (promocje dla dużych zamówień)
- Cena dla darczyńców indywidualnych (stała: 50 zł)
- Blokada zmiany ceny po rozpoczęciu edycji

#### 2.4 Zarządzanie użytkownikami
- Zakładanie kont liderów okręgowych
- Import liderów z CSV/Excel
- Zakładanie kont pracowników magazynu
- Wysyłka emaili z danymi dostępowymi

#### 2.5 Zamówienia i wysyłki
- Podgląd wszystkich zamówień
- Potwierdzanie zamówień → integracja z aPaczka.pl
- Drukowanie etykiet
- Śledzenie statusu przesyłek
- Historia wysyłek

#### 2.6 Rozliczenia
- Podgląd ile pakietów wysłano do każdego lidera
- Raportowanie zwrotów od liderów
- Obliczanie należności (wysłane - zwrócone × cena)
- Potwierdzanie wpłat
- Eksport raportów

### 3. Funkcjonalności Lidera Okręgu

#### 3.1 Zamawianie pakietów
- Minimalna ilość: 10 pakietów
- Wybór paczkomatu InPost/ORLEN (mapa Furgonetka.pl)
- Wielokrotne zamawianie w dowolnym momencie (do czasu blokady)
- Podgląd statusu zamówień

#### 3.2 Raportowanie sprzedaży
- Wprowadzanie ilości sprzedanych pakietów
- Automatyczne wyliczenie należności do zapłaty
- Historia raportów

#### 3.3 Zwroty
- Zgłaszanie zwrotów niesprzedanych pakietów
- Wybór paczkomatu do odbioru zwrotu

### 4. Strona publiczna (Cegiełki)

#### 4.1 Formularz darczyńcy
- Dane osobowe (email, imię, nazwisko, telefon)
- Ilość pakietów (cena: 50 zł/szt)
- Wybór paczkomatu InPost (mapa)
- Integracja Przelewy24

#### 4.2 Panel administracyjny cegiełek
- Edycja treści informacyjnej (zajawka)
- Podgląd zamówień od darczyńców
- Integracja z magazynem głównym

## Architektura Techniczna

### Stack technologiczny
- **Backend**: Ruby on Rails 8.x
- **Baza danych**: PostgreSQL 16
- **Frontend**: Tailwind CSS 4.x + TailAdmin Pro
- **Autentykacja**: Devise
- **Mailer**: Action Mailer + (Postmark/SendGrid)
- **Background Jobs**: Solid Queue (Rails 8 default)
- **Deploy**: Kamal 2.x
- **Integracje**:
  - aPaczka.pl API v2
  - Przelewy24 API
  - Furgonetka Map v2.0.1

### Struktura projektu

```
edk-admin-packages/
├── app/
│   ├── controllers/
│   │   ├── admin/           # Panel koordynatora
│   │   │   ├── dashboard_controller.rb
│   │   │   ├── editions_controller.rb
│   │   │   ├── users_controller.rb
│   │   │   ├── inventory_controller.rb
│   │   │   ├── orders_controller.rb
│   │   │   ├── shipments_controller.rb
│   │   │   ├── settlements_controller.rb
│   │   │   └── settings_controller.rb
│   │   ├── leader/          # Panel lidera okręgu
│   │   │   ├── dashboard_controller.rb
│   │   │   ├── orders_controller.rb
│   │   │   ├── sales_reports_controller.rb
│   │   │   └── returns_controller.rb
│   │   ├── warehouse/       # Panel pracownika magazynu
│   │   │   ├── dashboard_controller.rb
│   │   │   ├── orders_controller.rb
│   │   │   └── shipments_controller.rb
│   │   └── public/          # Strona publiczna cegiełki
│   │       ├── donations_controller.rb
│   │       └── webhooks_controller.rb
│   ├── models/
│   ├── services/
│   │   ├── apaczka/         # Integracja aPaczka
│   │   ├── przelewy24/      # Integracja płatności
│   │   └── inventory/       # Logika magazynowa
│   ├── jobs/
│   └── mailers/
├── config/
│   └── deploy.yml           # Kamal config
├── db/
│   └── migrate/
└── spec/                    # Testy RSpec
```

## Model Danych

### ERD (Entity Relationship Diagram)

```
┌─────────────────┐       ┌─────────────────┐
│    editions     │       │      users      │
├─────────────────┤       ├─────────────────┤
│ id              │       │ id              │
│ name            │       │ email           │
│ year            │       │ encrypted_pwd   │
│ status          │       │ first_name      │
│ is_active       │       │ last_name       │
│ ordering_locked │       │ phone           │
│ default_price   │       │ role            │
│ donor_price     │       │ created_by_id   │
│ created_at      │       │ created_at      │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │    ┌────────────────────┴────────────────────┐
         │    │                                         │
         ▼    ▼                                         ▼
┌─────────────────┐                           ┌─────────────────┐
│ leader_settings │                           │  area_groups    │
├─────────────────┤                           ├─────────────────┤
│ id              │                           │ id              │
│ user_id    (FK) │◄──────────────────────────│ leader_id  (FK) │
│ edition_id (FK) │                           │ edition_id (FK) │
│ custom_price    │                           │ name            │
│ ordering_locked │                           │ created_at      │
│ created_at      │                           └────────┬────────┘
└─────────────────┘                                    │
                                                       │
┌─────────────────┐       ┌─────────────────┐         │
│    inventory    │       │     orders      │         │
├─────────────────┤       ├─────────────────┤         │
│ id              │       │ id              │         │
│ edition_id (FK) │       │ edition_id (FK) │         │
│ total_stock     │       │ user_id    (FK) │◄────────┘
│ available       │       │ area_group_id   │
│ reserved        │       │ quantity        │
│ shipped         │       │ status          │
│ returned        │       │ locker_code     │
│ updated_at      │       │ locker_name     │
└─────────────────┘       │ locker_address  │
                          │ price_per_unit  │
┌─────────────────┐       │ total_amount    │
│inventory_moves  │       │ created_at      │
├─────────────────┤       │ confirmed_at    │
│ id              │       └────────┬────────┘
│ inventory_id    │                │
│ move_type       │                │
│ quantity        │                ▼
│ reference_type  │       ┌─────────────────┐
│ reference_id    │       │    shipments    │
│ notes           │       ├─────────────────┤
│ created_by_id   │       │ id              │
│ created_at      │       │ order_id   (FK) │
└─────────────────┘       │ apaczka_id      │
                          │ waybill_number  │
┌─────────────────┐       │ tracking_url    │
│  sales_reports  │       │ label_pdf       │
├─────────────────┤       │ status          │
│ id              │       │ shipped_at      │
│ user_id    (FK) │       │ delivered_at    │
│ edition_id (FK) │       │ created_at      │
│ quantity_sold   │       └─────────────────┘
│ reported_at     │
│ created_at      │       ┌─────────────────┐
└─────────────────┘       │    donations    │
                          ├─────────────────┤
┌─────────────────┐       │ id              │
│   settlements   │       │ edition_id (FK) │
├─────────────────┤       │ email           │
│ id              │       │ first_name      │
│ user_id    (FK) │       │ last_name       │
│ edition_id (FK) │       │ phone           │
│ total_sent      │       │ quantity        │
│ total_returned  │       │ amount          │
│ total_sold      │       │ locker_code     │
│ price_per_unit  │       │ locker_name     │
│ amount_due      │       │ payment_status  │
│ amount_paid     │       │ payment_id      │
│ status          │       │ shipment_id(FK) │
│ settled_at      │       │ created_at      │
│ created_at      │       └─────────────────┘
└─────────────────┘

┌─────────────────┐
│     returns     │
├─────────────────┤
│ id              │
│ user_id    (FK) │
│ edition_id (FK) │
│ quantity        │
│ status          │
│ locker_code     │
│ shipment_id(FK) │
│ received_at     │
│ created_at      │
└─────────────────┘
```

### Szczegóły modeli

#### 1. Edition (Edycja)
```ruby
# Status: draft, active, closed
# Tylko jedna edycja może być active w danym momencie
create_table :editions do |t|
  t.string :name, null: false              # "EDK 2026"
  t.integer :year, null: false
  t.string :status, default: 'draft'       # draft, active, closed
  t.boolean :is_active, default: false
  t.boolean :ordering_locked, default: false
  t.decimal :default_price, precision: 8, scale: 2, default: 30.0
  t.decimal :donor_price, precision: 8, scale: 2, default: 50.0
  t.timestamps
end
```

#### 2. User (Użytkownik)
```ruby
# Role: admin, warehouse, leader
create_table :users do |t|
  t.string :email, null: false
  t.string :encrypted_password, null: false
  t.string :first_name
  t.string :last_name
  t.string :phone
  t.string :role, default: 'leader'        # admin, warehouse, leader
  t.references :created_by, foreign_key: { to_table: :users }
  # Devise columns
  t.string :reset_password_token
  t.datetime :reset_password_sent_at
  t.datetime :remember_created_at
  t.integer :sign_in_count, default: 0
  t.datetime :current_sign_in_at
  t.datetime :last_sign_in_at
  t.timestamps
end
```

#### 3. AreaGroup (Okręg)
```ruby
create_table :area_groups do |t|
  t.references :leader, foreign_key: { to_table: :users }
  t.references :edition, null: false, foreign_key: true
  t.string :name, null: false
  t.timestamps
end
```

#### 4. LeaderSetting (Ustawienia Lidera per Edycja)
```ruby
create_table :leader_settings do |t|
  t.references :user, null: false, foreign_key: true
  t.references :edition, null: false, foreign_key: true
  t.decimal :custom_price, precision: 8, scale: 2
  t.boolean :ordering_locked, default: false
  t.timestamps

  t.index [:user_id, :edition_id], unique: true
end
```

#### 5. Inventory (Stan Magazynowy)
```ruby
create_table :inventories do |t|
  t.references :edition, null: false, foreign_key: true
  t.integer :total_stock, default: 0
  t.integer :available, default: 0
  t.integer :reserved, default: 0
  t.integer :shipped, default: 0
  t.integer :returned, default: 0
  t.timestamps

  t.index :edition_id, unique: true
end
```

#### 6. InventoryMove (Ruch Magazynowy)
```ruby
# move_type: stock_in, stock_out, reserve, ship, return, adjustment
create_table :inventory_moves do |t|
  t.references :inventory, null: false, foreign_key: true
  t.string :move_type, null: false
  t.integer :quantity, null: false
  t.string :reference_type               # Order, Donation, Return
  t.bigint :reference_id
  t.text :notes
  t.references :created_by, foreign_key: { to_table: :users }
  t.timestamps
end
```

#### 7. Order (Zamówienie od Lidera)
```ruby
# status: pending, confirmed, shipped, delivered, cancelled
create_table :orders do |t|
  t.references :edition, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.references :area_group, foreign_key: true
  t.integer :quantity, null: false
  t.string :status, default: 'pending'
  t.string :locker_code                   # Kod paczkomatu
  t.string :locker_name                   # Nazwa paczkomatu
  t.string :locker_address
  t.string :locker_city
  t.string :locker_post_code
  t.decimal :price_per_unit, precision: 8, scale: 2
  t.decimal :total_amount, precision: 10, scale: 2
  t.datetime :confirmed_at
  t.timestamps
end
```

#### 8. Shipment (Wysyłka)
```ruby
# status: pending, label_printed, shipped, in_transit, delivered, failed
create_table :shipments do |t|
  t.references :order, foreign_key: true
  t.references :donation, foreign_key: true
  t.string :apaczka_order_id
  t.string :waybill_number
  t.string :tracking_url
  t.binary :label_pdf
  t.string :status, default: 'pending'
  t.datetime :shipped_at
  t.datetime :delivered_at
  t.json :apaczka_response
  t.timestamps
end
```

#### 9. SalesReport (Raport Sprzedaży)
```ruby
create_table :sales_reports do |t|
  t.references :user, null: false, foreign_key: true
  t.references :edition, null: false, foreign_key: true
  t.integer :quantity_sold, null: false
  t.datetime :reported_at, null: false
  t.text :notes
  t.timestamps
end
```

#### 10. Settlement (Rozliczenie)
```ruby
# status: pending, calculated, paid, closed
create_table :settlements do |t|
  t.references :user, null: false, foreign_key: true
  t.references :edition, null: false, foreign_key: true
  t.integer :total_sent, default: 0
  t.integer :total_returned, default: 0
  t.integer :total_sold, default: 0
  t.decimal :price_per_unit, precision: 8, scale: 2
  t.decimal :amount_due, precision: 10, scale: 2
  t.decimal :amount_paid, precision: 10, scale: 2, default: 0
  t.string :status, default: 'pending'
  t.datetime :settled_at
  t.timestamps

  t.index [:user_id, :edition_id], unique: true
end
```

#### 11. Donation (Darowizna od darczyńcy indywidualnego)
```ruby
# payment_status: pending, paid, failed, refunded
create_table :donations do |t|
  t.references :edition, null: false, foreign_key: true
  t.string :email, null: false
  t.string :first_name
  t.string :last_name
  t.string :phone
  t.integer :quantity, null: false
  t.decimal :amount, precision: 10, scale: 2
  t.string :locker_code
  t.string :locker_name
  t.string :locker_address
  t.string :locker_city
  t.string :locker_post_code
  t.string :payment_status, default: 'pending'
  t.string :payment_id                    # Przelewy24 session_id
  t.string :payment_transaction_id
  t.timestamps
end
```

#### 12. Return (Zwrot od Lidera)
```ruby
# status: requested, approved, shipped, received, rejected
create_table :returns do |t|
  t.references :user, null: false, foreign_key: true
  t.references :edition, null: false, foreign_key: true
  t.integer :quantity, null: false
  t.string :status, default: 'requested'
  t.string :locker_code
  t.string :locker_name
  t.text :notes
  t.datetime :received_at
  t.timestamps
end
```

## Integracje Zewnętrzne

### 1. aPaczka.pl API v2

#### Konfiguracja
```ruby
# config/credentials.yml.enc
apaczka:
  app_id: "xxx"
  app_secret: "xxx"
  sender_name: "Rafał Wojtkiewicz"
  sender_street: "..."
  sender_city: "..."
  sender_post_code: "..."
  sender_phone: "..."
  sender_email: "..."
```

#### Serwis integracyjny
```ruby
# app/services/apaczka/client.rb
module Apaczka
  class Client
    BASE_URL = "https://www.apaczka.pl/api/v2"

    def create_shipment(order)
      # POST /order_send/
    end

    def get_waybill(order_id)
      # GET /waybill/:order_id/
    end

    def get_order_status(order_id)
      # GET /order/:order_id/
    end

    def get_points(type: 'INPOST_COURIER_POINT')
      # GET /points/:type/
    end

    private

    def sign_request(route, data, expires)
      # HMAC-SHA256 signature
    end
  end
end
```

### 2. Furgonetka Map v2.0.1

**Dokumentacja**: https://furgonetka.pl/files/docs/furgonetka-mapa-2.0.1.pdf
**Mapa demo**: https://furgonetka.pl/mapa

#### Konfiguracja i użycie
```javascript
// app/javascript/controllers/parcel_locker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "name", "address", "city", "postCode"]

  connect() {
    this.loadFurgonetkaScript()
  }

  loadFurgonetkaScript() {
    const script = document.createElement('script')
    script.src = 'https://furgonetka.pl/js/dist/map/map.js'
    script.onload = () => this.scriptLoaded = true
    document.head.appendChild(script)
  }

  openMap() {
    new window.Furgonetka.Map({
      courierServices: ['inpost'],
      type: 'parcel_machine',
      pointTypesFilter: ['parcel_machine'],
      callback: (params) => this.onPointSelected(params),
      zoom: 14,
    }).show()
  }

  onPointSelected(params) {
    const { code, name, address } = params.point
    this.codeTarget.value = code
    this.nameTarget.value = name
    this.addressTarget.value = address.street
    this.cityTarget.value = address.city
    this.postCodeTarget.value = address.postCode
  }
}
```

### 3. Przelewy24 API

```ruby
# app/services/przelewy24/client.rb
module Przelewy24
  class Client
    SANDBOX_URL = "https://sandbox.przelewy24.pl"
    PRODUCTION_URL = "https://secure.przelewy24.pl"

    def initialize
      @merchant_id = Rails.application.credentials.przelewy24[:merchant_id]
      @pos_id = Rails.application.credentials.przelewy24[:pos_id]
      @crc_key = Rails.application.credentials.przelewy24[:crc_key]
      @api_key = Rails.application.credentials.przelewy24[:api_key]
    end

    def create_transaction(donation)
      # POST /api/v1/transaction/register
    end

    def verify_transaction(params)
      # PUT /api/v1/transaction/verify
    end

    private

    def calculate_sign(data)
      # SHA-384 hash
    end
  end
end
```

## Fazy Implementacji

---

## Phase 1: Fundament Projektu

### Overview
Inicjalizacja projektu Rails 8, konfiguracja bazy danych, autentykacja Devise, podstawowa struktura UI z TailAdmin.

### Changes Required:

#### 1.1 Inicjalizacja projektu Rails 8
```bash
rails new edk-admin-packages \
  --database=postgresql \
  --css=tailwind \
  --skip-test \
  --skip-system-test
```

#### 1.2 Dodanie gemów
**File**: `Gemfile`
```ruby
# Authentication
gem 'devise'

# Authorization
gem 'pundit'

# Pagination
gem 'pagy'

# CSV/Excel import
gem 'roo'

# HTTP client for API integrations
gem 'faraday'

# JSON serialization
gem 'blueprinter'

# Background jobs (Rails 8 default)
gem 'solid_queue'

# PDF generation for labels
gem 'prawn'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end
```

#### 1.3 Konfiguracja bazy danych
**File**: `config/database.yml`
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: edk_admin_packages_development

test:
  <<: *default
  database: edk_admin_packages_test

production:
  <<: *default
  database: edk_admin_packages_production
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] %>
```

#### 1.4 Instalacja i konfiguracja Devise

**UWAGA**: Rejestracja NIE jest dostępna publicznie - tylko admin może tworzyć konta użytkowników.

```bash
rails generate devise:install
rails generate devise User
rails generate devise:views  # Generowanie widoków do customizacji
```

**File**: `app/models/user.rb`
```ruby
class User < ApplicationRecord
  # UWAGA: Brak :registerable - rejestracja tylko przez admina
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum :role, { leader: 'leader', warehouse: 'warehouse', admin: 'admin' }

  belongs_to :created_by, class_name: 'User', optional: true
  has_many :created_users, class_name: 'User', foreign_key: 'created_by_id'
  has_many :area_groups, foreign_key: 'leader_id'
  has_many :orders
  has_many :sales_reports
  has_many :settlements
  has_many :returns
  has_many :leader_settings

  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: roles.keys }

  def full_name
    "#{first_name} #{last_name}"
  end

  def effective_price_for(edition)
    leader_settings.find_by(edition: edition)&.custom_price || edition.default_price
  end

  def ordering_locked_for?(edition)
    edition.ordering_locked || leader_settings.find_by(edition: edition)&.ordering_locked
  end
end
```

#### 1.5 Migracje bazodanowe
**File**: `db/migrate/xxx_add_fields_to_users.rb`
```ruby
class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone, :string
    add_column :users, :role, :string, default: 'leader'
    add_reference :users, :created_by, foreign_key: { to_table: :users }

    add_index :users, :role
  end
end
```

**File**: `db/migrate/xxx_create_editions.rb`
```ruby
class CreateEditions < ActiveRecord::Migration[8.0]
  def change
    create_table :editions do |t|
      t.string :name, null: false
      t.integer :year, null: false
      t.string :status, default: 'draft'
      t.boolean :is_active, default: false
      t.boolean :ordering_locked, default: false
      t.decimal :default_price, precision: 8, scale: 2, default: 30.0
      t.decimal :donor_price, precision: 8, scale: 2, default: 50.0
      t.timestamps
    end

    add_index :editions, :year, unique: true
    add_index :editions, :is_active
  end
end
```

#### 1.6 Instalacja TailAdmin i konfiguracja stylów

**Źródło wzorców UI**: https://demo.tailadmin.com/

Kluczowe strony demo do odwzorowania:
- Dashboard: https://demo.tailadmin.com/
- Lista produktów (wzorzec dla list): https://demo.tailadmin.com/products-list
- Dodawanie produktu (wzorzec dla formularzy): https://demo.tailadmin.com/add-product
- Logowanie: https://demo.tailadmin.com/signin
- Reset hasła: https://demo.tailadmin.com/reset-password

**Kroki instalacji TailAdmin:**

1. Skopiowanie plików CSS TailAdmin do `app/assets/tailwind/`
2. Konfiguracja Tailwind CSS dla custom colors i fontów
3. Dodanie fontów Inter/Satoshi
4. Utworzenie layout'ów dla różnych ról
5. Utworzenie partiali dla komponentów (sidebar, header, cards)

**File**: `app/assets/tailwind/application.css`
```css
@import "tailwindcss";

/* TailAdmin Custom Theme */
@theme {
  --color-primary: #3C50E0;
  --color-primary-dark: #1C3FB7;
  --color-secondary: #80CAEE;
  --color-stroke: #E2E8F0;
  --color-stroke-dark: #2E3A47;
  --color-body: #64748B;
  --color-body-dark: #AEB7C0;
  --color-body-light: #DEE4EE;
  --color-box-dark: #24303F;
  --color-box-dark-2: #1A222C;
  --color-meta-1: #DC3545;
  --color-meta-2: #EFF4FB;
  --color-meta-3: #10B981;
  --color-meta-4: #313D4A;
  --color-meta-5: #259AE6;
  --color-meta-6: #FFBA00;
  --color-meta-7: #FF6766;
  --color-meta-8: #F0950C;
  --color-meta-9: #E5E5E5;
  --color-meta-10: #5B8FF9;
  --color-success: #219653;
  --color-danger: #D34053;
  --color-warning: #FFA70B;
  --color-graydark: #333A48;
  --color-whiten: #F1F5F9;
  --color-whiter: #F5F7FD;
  --color-boxdark: #24303F;
  --color-boxdark-2: #1A222C;
  --font-family-satoshi: 'Satoshi', sans-serif;
}

/* Dark mode support */
.dark {
  --color-bg: #1A222C;
  --color-text: #AEB7C0;
}
```

**File**: `app/views/layouts/admin.html.erb`
```erb
<!DOCTYPE html>
<html lang="pl" class="<%= cookies[:theme] || 'light' %>">
<head>
  <title>EDK Packages - Admin</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
  <!-- Fonty -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body class="font-inter text-base bg-gray-50 dark:bg-boxdark-2 text-body dark:text-body-dark">
  <div class="flex h-screen overflow-hidden">
    <%= render 'layouts/admin/sidebar' %>
    <div class="relative flex flex-1 flex-col overflow-y-auto overflow-x-hidden">
      <%= render 'layouts/admin/header' %>
      <main class="p-4 md:p-6 2xl:p-10">
        <% if notice.present? %>
          <div class="mb-4 rounded-lg bg-success/10 border border-success px-4 py-3 text-success">
            <%= notice %>
          </div>
        <% end %>
        <% if alert.present? %>
          <div class="mb-4 rounded-lg bg-danger/10 border border-danger px-4 py-3 text-danger">
            <%= alert %>
          </div>
        <% end %>
        <%= yield %>
      </main>
    </div>
  </div>
</body>
</html>
```

#### 1.7 Widoki autentykacji TailAdmin

**UWAGA**: Widoki oparte na demo TailAdmin:
- Logowanie: https://demo.tailadmin.com/signin
- Reset hasła: https://demo.tailadmin.com/reset-password

**File**: `app/views/layouts/auth.html.erb` (layout dla stron auth)
```erb
<!DOCTYPE html>
<html lang="pl">
<head>
  <title>EDK Packages - <%= yield :page_title %></title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
<body class="font-inter bg-gray-50 dark:bg-boxdark-2">
  <div class="flex min-h-screen items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
    <%= yield %>
  </div>
</body>
</html>
```

**File**: `app/views/devise/sessions/new.html.erb` (strona logowania)
```erb
<% content_for :page_title, "Logowanie" %>

<div class="w-full max-w-md">
  <!-- Logo -->
  <div class="mb-8 text-center">
    <h1 class="text-2xl font-bold text-gray-900 dark:text-white">EDK Packages</h1>
    <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">System zarządzania pakietami EDK</p>
  </div>

  <!-- Card -->
  <div class="rounded-xl bg-white p-8 shadow-lg dark:bg-boxdark">
    <div class="mb-6">
      <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Zaloguj się</h2>
      <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">Wprowadź dane aby kontynuować</p>
    </div>

    <%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { class: "space-y-5" }) do |f| %>
      <!-- Email -->
      <div>
        <label for="email" class="mb-2.5 block font-medium text-gray-900 dark:text-white">
          Email <span class="text-danger">*</span>
        </label>
        <div class="relative">
          <%= f.email_field :email,
              autofocus: true,
              autocomplete: "email",
              placeholder: "Wprowadź email",
              class: "w-full rounded-lg border border-stroke bg-transparent py-3 pl-4 pr-10 outline-none focus:border-primary focus-visible:shadow-none dark:border-stroke-dark dark:bg-boxdark dark:text-white" %>
          <span class="absolute right-4 top-3.5">
            <svg class="fill-current text-gray-400" width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M19.2516 3.30005H2.75156C1.58281 3.30005 0.585938 4.26255 0.585938 5.46567V16.6032C0.585938 17.7719 1.54844 18.7688 2.75156 18.7688H19.2516C20.4203 18.7688 21.4172 17.8063 21.4172 16.6032V5.4313C21.4172 4.26255 20.4203 3.30005 19.2516 3.30005ZM19.2516 4.84692C19.2859 4.84692 19.3203 4.84692 19.3547 4.84692L11.0016 10.2094L2.64844 4.84692C2.68281 4.84692 2.71719 4.84692 2.75156 4.84692H19.2516ZM19.2516 17.1532H2.75156C2.40781 17.1532 2.13281 16.8782 2.13281 16.5344V6.35942L10.1766 11.5157C10.4172 11.6875 10.6922 11.7563 10.9672 11.7563C11.2422 11.7563 11.5172 11.6875 11.7578 11.5157L19.8016 6.35942V16.5688C19.8703 16.9125 19.5953 17.1532 19.2516 17.1532Z" fill=""/>
            </svg>
          </span>
        </div>
      </div>

      <!-- Password -->
      <div>
        <label for="password" class="mb-2.5 block font-medium text-gray-900 dark:text-white">
          Hasło <span class="text-danger">*</span>
        </label>
        <div class="relative">
          <%= f.password_field :password,
              autocomplete: "current-password",
              placeholder: "Wprowadź hasło",
              class: "w-full rounded-lg border border-stroke bg-transparent py-3 pl-4 pr-10 outline-none focus:border-primary focus-visible:shadow-none dark:border-stroke-dark dark:bg-boxdark dark:text-white" %>
          <span class="absolute right-4 top-3.5">
            <svg class="fill-current text-gray-400" width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M16.1547 6.80626V5.91251C16.1547 3.16251 14.0922 0.825012 11.4797 0.618762C10.0359 0.481262 8.59219 0.996887 7.52656 1.95938C6.46094 2.92188 5.84219 4.29688 5.84219 5.70626V6.80626C3.84844 7.18438 2.33594 8.93751 2.33594 11.0688V17.2906C2.33594 19.5594 4.19219 21.3813 6.42656 21.3813H15.5765C17.8453 21.3813 19.6672 19.525 19.6672 17.2906V11.0688C19.6672 8.93751 18.1547 7.18438 16.1547 6.80626ZM8.55781 3.09376C9.31406 2.40626 10.3109 2.06251 11.3422 2.16563C13.1641 2.33751 14.6078 3.98751 14.6078 5.91251V6.70313H7.38906V5.67188C7.38906 4.70938 7.80156 3.78126 8.55781 3.09376ZM18.1203 17.2906C18.1203 18.7 16.9859 19.8344 15.5765 19.8344H6.42656C5.01719 19.8344 3.88281 18.7 3.88281 17.2906V11.0688C3.88281 9.52189 5.15469 8.25001 6.70156 8.25001H15.2953C16.8422 8.25001 18.1141 9.52189 18.1141 11.0688V17.2906H18.1203Z" fill=""/>
            </svg>
          </span>
        </div>
      </div>

      <!-- Remember me & Forgot password -->
      <div class="flex items-center justify-between">
        <label class="flex items-center gap-2 cursor-pointer select-none">
          <%= f.check_box :remember_me, class: "h-4 w-4 rounded border-stroke text-primary focus:ring-primary dark:border-stroke-dark" %>
          <span class="text-sm text-gray-600 dark:text-gray-400">Zapamiętaj mnie</span>
        </label>

        <%= link_to "Zapomniałeś hasła?", new_password_path(resource_name), class: "text-sm text-primary hover:underline" %>
      </div>

      <!-- Submit -->
      <div>
        <%= f.submit "Zaloguj się",
            class: "w-full cursor-pointer rounded-lg bg-primary py-3 px-4 font-medium text-white transition hover:bg-primary-dark" %>
      </div>
    <% end %>
  </div>
</div>
```

**File**: `app/views/devise/passwords/new.html.erb` (reset hasła)
```erb
<% content_for :page_title, "Reset hasła" %>

<div class="w-full max-w-md">
  <!-- Logo -->
  <div class="mb-8 text-center">
    <h1 class="text-2xl font-bold text-gray-900 dark:text-white">EDK Packages</h1>
    <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">System zarządzania pakietami EDK</p>
  </div>

  <!-- Card -->
  <div class="rounded-xl bg-white p-8 shadow-lg dark:bg-boxdark">
    <div class="mb-6">
      <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Resetuj hasło</h2>
      <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">Wyślemy Ci link do zresetowania hasła</p>
    </div>

    <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :post, class: "space-y-5" }) do |f| %>
      <%= render "devise/shared/error_messages", resource: resource %>

      <!-- Email -->
      <div>
        <label for="email" class="mb-2.5 block font-medium text-gray-900 dark:text-white">
          Email <span class="text-danger">*</span>
        </label>
        <div class="relative">
          <%= f.email_field :email,
              autofocus: true,
              autocomplete: "email",
              placeholder: "Wprowadź email",
              class: "w-full rounded-lg border border-stroke bg-transparent py-3 pl-4 pr-10 outline-none focus:border-primary focus-visible:shadow-none dark:border-stroke-dark dark:bg-boxdark dark:text-white" %>
          <span class="absolute right-4 top-3.5">
            <svg class="fill-current text-gray-400" width="22" height="22" viewBox="0 0 22 22" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M19.2516 3.30005H2.75156C1.58281 3.30005 0.585938 4.26255 0.585938 5.46567V16.6032C0.585938 17.7719 1.54844 18.7688 2.75156 18.7688H19.2516C20.4203 18.7688 21.4172 17.8063 21.4172 16.6032V5.4313C21.4172 4.26255 20.4203 3.30005 19.2516 3.30005ZM19.2516 4.84692C19.2859 4.84692 19.3203 4.84692 19.3547 4.84692L11.0016 10.2094L2.64844 4.84692C2.68281 4.84692 2.71719 4.84692 2.75156 4.84692H19.2516ZM19.2516 17.1532H2.75156C2.40781 17.1532 2.13281 16.8782 2.13281 16.5344V6.35942L10.1766 11.5157C10.4172 11.6875 10.6922 11.7563 10.9672 11.7563C11.2422 11.7563 11.5172 11.6875 11.7578 11.5157L19.8016 6.35942V16.5688C19.8703 16.9125 19.5953 17.1532 19.2516 17.1532Z" fill=""/>
            </svg>
          </span>
        </div>
      </div>

      <!-- Submit -->
      <div>
        <%= f.submit "Wyślij link resetujący",
            class: "w-full cursor-pointer rounded-lg bg-primary py-3 px-4 font-medium text-white transition hover:bg-primary-dark" %>
      </div>
    <% end %>

    <!-- Back to login -->
    <div class="mt-6 text-center">
      <%= link_to "Wróć do logowania", new_session_path(resource_name), class: "text-sm text-primary hover:underline" %>
    </div>
  </div>
</div>
```

**File**: `app/views/devise/passwords/edit.html.erb` (ustaw nowe hasło)
```erb
<% content_for :page_title, "Nowe hasło" %>

<div class="w-full max-w-md">
  <!-- Logo -->
  <div class="mb-8 text-center">
    <h1 class="text-2xl font-bold text-gray-900 dark:text-white">EDK Packages</h1>
    <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">System zarządzania pakietami EDK</p>
  </div>

  <!-- Card -->
  <div class="rounded-xl bg-white p-8 shadow-lg dark:bg-boxdark">
    <div class="mb-6">
      <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Ustaw nowe hasło</h2>
      <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">Wprowadź nowe hasło dla swojego konta</p>
    </div>

    <%= form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :put, class: "space-y-5" }) do |f| %>
      <%= render "devise/shared/error_messages", resource: resource %>
      <%= f.hidden_field :reset_password_token %>

      <!-- New Password -->
      <div>
        <label for="password" class="mb-2.5 block font-medium text-gray-900 dark:text-white">
          Nowe hasło <span class="text-danger">*</span>
        </label>
        <%= f.password_field :password,
            autofocus: true,
            autocomplete: "new-password",
            placeholder: "Minimum 6 znaków",
            class: "w-full rounded-lg border border-stroke bg-transparent py-3 pl-4 pr-10 outline-none focus:border-primary focus-visible:shadow-none dark:border-stroke-dark dark:bg-boxdark dark:text-white" %>
      </div>

      <!-- Confirm Password -->
      <div>
        <label for="password_confirmation" class="mb-2.5 block font-medium text-gray-900 dark:text-white">
          Potwierdź hasło <span class="text-danger">*</span>
        </label>
        <%= f.password_field :password_confirmation,
            autocomplete: "new-password",
            placeholder: "Powtórz hasło",
            class: "w-full rounded-lg border border-stroke bg-transparent py-3 pl-4 pr-10 outline-none focus:border-primary focus-visible:shadow-none dark:border-stroke-dark dark:bg-boxdark dark:text-white" %>
      </div>

      <!-- Submit -->
      <div>
        <%= f.submit "Zmień hasło",
            class: "w-full cursor-pointer rounded-lg bg-primary py-3 px-4 font-medium text-white transition hover:bg-primary-dark" %>
      </div>
    <% end %>
  </div>
</div>
```

**File**: `app/views/devise/shared/_error_messages.html.erb`
```erb
<% if resource.errors.any? %>
  <div class="rounded-lg bg-danger/10 border border-danger px-4 py-3 mb-4">
    <h3 class="font-medium text-danger">
      <%= I18n.t("errors.messages.not_saved",
                count: resource.errors.count,
                resource: resource.class.model_name.human.downcase) %>
    </h3>
    <ul class="mt-2 list-disc list-inside text-sm text-danger">
      <% resource.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

**File**: `app/controllers/application_controller.rb` (ustawienie layoutu dla Devise)
```ruby
class ApplicationController < ActionController::Base
  layout :layout_by_resource

  private

  def layout_by_resource
    if devise_controller?
      'auth'
    else
      'application'
    end
  end
end
```

#### 1.8 TailAdmin Component Patterns (do użycia w późniejszych fazach)

**Wzorzec dla stron listy** (na podstawie https://demo.tailadmin.com/products-list):
- Header z breadcrumb (Home > Sekcja > Lista)
- Tytuł strony z opisem
- Panel filtrów z dropdownami i przyciskiem "Zastosuj"
- Tabela z kolumnami, sortowaniem, checkbox do zaznaczania
- Paginacja z informacją "Pokazuje X-Y z Z"
- Przyciski akcji: Export, Dodaj nowy

**Wzorzec dla formularzy** (na podstawie https://demo.tailadmin.com/add-product):
- Sekcje formularza z nagłówkami (np. "Opis produktu", "Ceny i dostępność")
- Pola tekstowe z labelami i asteryskami dla wymaganych
- Dropdowny dla wyboru kategorii, statusów
- Textarea dla dłuższych opisów
- Przyciski na dole: "Zapisz jako szkic", "Opublikuj"

**File**: `app/views/shared/_page_header.html.erb` (nagłówek strony)
```erb
<%# locals: (title:, description: nil, breadcrumbs: [], actions: nil) %>
<div class="mb-6">
  <!-- Breadcrumb -->
  <nav class="mb-4">
    <ol class="flex items-center gap-2 text-sm">
      <li><%= link_to "Dashboard", root_path, class: "text-gray-500 hover:text-primary" %></li>
      <% breadcrumbs.each do |crumb| %>
        <li class="flex items-center gap-2">
          <span class="text-gray-400">/</span>
          <% if crumb[:path] %>
            <%= link_to crumb[:title], crumb[:path], class: "text-gray-500 hover:text-primary" %>
          <% else %>
            <span class="text-primary"><%= crumb[:title] %></span>
          <% end %>
        </li>
      <% end %>
    </ol>
  </nav>

  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-semibold text-gray-900 dark:text-white"><%= title %></h1>
      <% if description %>
        <p class="mt-1 text-sm text-gray-600 dark:text-gray-400"><%= description %></p>
      <% end %>
    </div>
    <% if actions %>
      <div class="flex gap-3">
        <%= actions %>
      </div>
    <% end %>
  </div>
</div>
```

**File**: `app/views/shared/_data_table.html.erb` (tabela danych)
```erb
<%# locals: (columns:, rows:, empty_message: "Brak danych") %>
<div class="rounded-xl border border-stroke bg-white shadow-lg dark:border-stroke-dark dark:bg-boxdark">
  <div class="overflow-x-auto">
    <table class="w-full table-auto">
      <thead>
        <tr class="bg-gray-50 dark:bg-meta-4">
          <% columns.each do |col| %>
            <th class="px-4 py-4 font-medium text-left text-gray-900 dark:text-white">
              <%= col[:label] %>
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <% if rows.any? %>
          <% rows.each do |row| %>
            <tr class="border-t border-stroke dark:border-stroke-dark">
              <%= row %>
            </tr>
          <% end %>
        <% else %>
          <tr>
            <td colspan="<%= columns.size %>" class="px-4 py-8 text-center text-gray-500">
              <%= empty_message %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

**File**: `app/views/shared/_form_section.html.erb` (sekcja formularza)
```erb
<%# locals: (title:, &block) %>
<div class="rounded-xl border border-stroke bg-white p-6 shadow-lg dark:border-stroke-dark dark:bg-boxdark">
  <h3 class="mb-5 text-lg font-semibold text-gray-900 dark:text-white"><%= title %></h3>
  <%= yield %>
</div>
```

**File**: `app/helpers/tailadmin_helper.rb` (helper dla komponentów)
```ruby
module TailadminHelper
  # Klasa dla pola input
  def tailadmin_input_class
    "w-full rounded-lg border border-stroke bg-transparent py-3 px-4 outline-none focus:border-primary dark:border-stroke-dark dark:bg-boxdark dark:text-white"
  end

  # Klasa dla przycisku primary
  def tailadmin_btn_primary_class
    "inline-flex items-center justify-center rounded-lg bg-primary px-6 py-3 font-medium text-white hover:bg-primary-dark transition"
  end

  # Klasa dla przycisku secondary
  def tailadmin_btn_secondary_class
    "inline-flex items-center justify-center rounded-lg border border-stroke bg-transparent px-6 py-3 font-medium text-gray-900 hover:bg-gray-50 transition dark:border-stroke-dark dark:text-white dark:hover:bg-meta-4"
  end

  # Klasa dla badge status
  def tailadmin_badge_class(status)
    case status.to_s
    when 'active', 'delivered', 'paid'
      "inline-flex rounded-full bg-success/10 px-3 py-1 text-sm font-medium text-success"
    when 'pending', 'draft'
      "inline-flex rounded-full bg-warning/10 px-3 py-1 text-sm font-medium text-warning"
    when 'cancelled', 'closed', 'unpaid'
      "inline-flex rounded-full bg-danger/10 px-3 py-1 text-sm font-medium text-danger"
    else
      "inline-flex rounded-full bg-gray-100 px-3 py-1 text-sm font-medium text-gray-600"
    end
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] `bin/rails db:create db:migrate` działa bez błędów
- [x] `bundle exec rspec` (podstawowe testy) przechodzi
- [x] `bin/rails routes` pokazuje ścieżki Devise (bez /users/sign_up - rejestracja wyłączona)
- [x] `bin/rails server` uruchamia aplikację bez błędów

#### Manual Verification:
- [x] Strona logowania (`/users/sign_in`) wyświetla się w stylu TailAdmin (https://demo.tailadmin.com/signin)
- [x] Strona reset hasła (`/users/password/new`) wyświetla się w stylu TailAdmin
- [x] Rejestracja NIE jest dostępna publicznie (brak `/users/sign_up`)
- [x] Można założyć konto użytkownika przez konsolę Rails: `User.create!(email: "admin@edk.pl", password: "password123", first_name: "Admin", last_name: "EDK", role: :admin)`
- [x] Layout TailAdmin z custom colors (brand: #465fff) renderuje się poprawnie
- [x] Formularze mają zaokrąglone pola input z ikonami (email, password)
- [x] Przyciski mają hover effect i transition

---

## Phase 2: Core Models i Logika Magazynowa

### Overview
Implementacja wszystkich modeli danych, walidacji, relacji oraz logiki zarządzania magazynem.

### Changes Required:

#### 2.1 Wszystkie migracje
Utworzenie migracji dla wszystkich tabel: `editions`, `area_groups`, `leader_settings`, `inventories`, `inventory_moves`, `orders`, `shipments`, `sales_reports`, `settlements`, `donations`, `returns`.

#### 2.2 Modele z walidacjami

**File**: `app/models/edition.rb`
```ruby
class Edition < ApplicationRecord
  enum :status, { draft: 'draft', active: 'active', closed: 'closed' }

  has_many :area_groups, dependent: :destroy
  has_many :leader_settings, dependent: :destroy
  has_one :inventory, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :donations, dependent: :destroy
  has_many :settlements, dependent: :destroy
  has_many :returns, dependent: :destroy
  has_many :sales_reports, dependent: :destroy

  validates :name, :year, presence: true
  validates :year, uniqueness: true
  validates :default_price, :donor_price, numericality: { greater_than: 0 }

  validate :only_one_active_edition

  after_create :create_inventory

  scope :current, -> { find_by(is_active: true) || order(year: :desc).first }

  def lock_ordering!
    update!(ordering_locked: true)
  end

  def unlock_ordering!
    update!(ordering_locked: false)
  end

  private

  def only_one_active_edition
    if is_active && Edition.where(is_active: true).where.not(id: id).exists?
      errors.add(:is_active, "może być tylko jedna aktywna edycja")
    end
  end

  def create_inventory
    Inventory.create!(edition: self)
  end
end
```

**File**: `app/models/order.rb`
```ruby
class Order < ApplicationRecord
  enum :status, {
    pending: 'pending',
    confirmed: 'confirmed',
    shipped: 'shipped',
    delivered: 'delivered',
    cancelled: 'cancelled'
  }

  belongs_to :edition
  belongs_to :user
  belongs_to :area_group, optional: true
  has_one :shipment, dependent: :destroy

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 10 }
  validates :locker_code, :locker_name, presence: true

  validate :ordering_not_locked
  validate :sufficient_inventory, on: :create

  before_create :set_price
  before_create :reserve_inventory
  after_create :send_notification

  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :pending, -> { where(status: :pending) }

  def confirm!
    transaction do
      update!(status: :confirmed, confirmed_at: Time.current)
      Apaczka::CreateShipmentJob.perform_later(self)
    end
  end

  def cancel!
    transaction do
      update!(status: :cancelled)
      edition.inventory.release_reserved(quantity)
    end
  end

  private

  def ordering_not_locked
    if user.ordering_locked_for?(edition)
      errors.add(:base, "Zamawianie pakietów jest zablokowane")
    end
  end

  def sufficient_inventory
    if edition.inventory.available < quantity
      errors.add(:quantity, "Niewystarczająca ilość pakietów na magazynie")
    end
  end

  def set_price
    self.price_per_unit = user.effective_price_for(edition)
    self.total_amount = quantity * price_per_unit
  end

  def reserve_inventory
    edition.inventory.reserve(quantity)
  end

  def send_notification
    OrderMailer.new_order(self).deliver_later
  end
end
```

**File**: `app/models/inventory.rb`
```ruby
class Inventory < ApplicationRecord
  belongs_to :edition
  has_many :inventory_moves, dependent: :destroy

  validates :total_stock, :available, :reserved, :shipped, :returned,
            numericality: { greater_than_or_equal_to: 0 }

  def add_stock(quantity, notes: nil, user: nil)
    transaction do
      self.total_stock += quantity
      self.available += quantity
      save!

      record_move(:stock_in, quantity, notes: notes, user: user)
    end
  end

  def reserve(quantity)
    transaction do
      raise InsufficientStock if available < quantity

      self.available -= quantity
      self.reserved += quantity
      save!

      record_move(:reserve, quantity)
    end
  end

  def release_reserved(quantity)
    transaction do
      self.reserved -= quantity
      self.available += quantity
      save!

      record_move(:release, quantity)
    end
  end

  def ship(quantity, reference: nil)
    transaction do
      self.reserved -= quantity
      self.shipped += quantity
      save!

      record_move(:ship, quantity, reference: reference)
    end
  end

  def receive_return(quantity, reference: nil)
    transaction do
      self.returned += quantity
      self.available += quantity
      save!

      record_move(:return, quantity, reference: reference)
    end
  end

  private

  def record_move(move_type, quantity, notes: nil, user: nil, reference: nil)
    inventory_moves.create!(
      move_type: move_type,
      quantity: quantity,
      notes: notes,
      created_by: user,
      reference: reference
    )
  end

  class InsufficientStock < StandardError; end
end
```

### Success Criteria:

#### Automated Verification:
- [x] `bin/rails db:migrate` działa bez błędów
- [x] `bundle exec rspec spec/models/` - wszystkie testy modeli przechodzą
- [x] Walidacje działają poprawnie (sprawdzenie w konsoli)
- [x] Relacje między modelami są poprawne

#### Manual Verification:
- [x] Można utworzyć edycję i automatycznie tworzy się inventory
- [x] Rezerwacja zmniejsza `available` i zwiększa `reserved`
- [x] Wysyłka przenosi z `reserved` do `shipped`
- [x] Zwrot zwiększa `available` i `returned`

---

## Phase 3: Panel Koordynatora (Admin)

### Overview
Kompletny panel administracyjny dla Rafała z dashboardem, zarządzaniem użytkownikami, magazynem, cenami i edycjami.

### Changes Required:

#### 3.1 Routing
**File**: `config/routes.rb`
```ruby
Rails.application.routes.draw do
  devise_for :users

  authenticate :user, ->(u) { u.admin? } do
    namespace :admin do
      root 'dashboard#index'

      resources :editions do
        member do
          post :activate
          post :lock_ordering
          post :unlock_ordering
          post :copy_from_previous
        end
      end

      resources :users do
        collection do
          get :import
          post :import, action: :process_import
        end
        member do
          post :lock_ordering
          post :unlock_ordering
        end
      end

      resource :inventory, only: [:show, :edit, :update] do
        post :add_stock
        get :movements
      end

      resources :orders do
        member do
          post :confirm
          post :cancel
          get :print_label
        end
      end

      resources :shipments, only: [:index, :show] do
        member do
          post :refresh_status
        end
      end

      resources :settlements do
        member do
          post :mark_paid
          post :recalculate
        end
      end

      resources :donations, only: [:index, :show]

      resources :settings, only: [:index, :update]
    end
  end

  authenticate :user, ->(u) { u.warehouse? } do
    namespace :warehouse do
      root 'dashboard#index'
      resources :orders, only: [:index, :show] do
        member do
          post :confirm
          get :print_label
        end
      end
      resources :shipments, only: [:index, :show]
    end
  end

  authenticate :user, ->(u) { u.leader? } do
    namespace :leader do
      root 'dashboard#index'
      resources :orders, only: [:index, :new, :create, :show]
      resources :sales_reports, only: [:index, :new, :create]
      resources :returns, only: [:index, :new, :create, :show]
    end
  end

  # Public donation page
  scope module: 'public' do
    get 'cegielka', to: 'donations#new'
    post 'cegielka', to: 'donations#create'
    get 'cegielka/sukces', to: 'donations#success'
    post 'webhooks/przelewy24', to: 'webhooks#przelewy24'
  end

  root 'home#index'
end
```

#### 3.2 Dashboard Controller
**File**: `app/controllers/admin/dashboard_controller.rb`
```ruby
module Admin
  class DashboardController < Admin::BaseController
    def index
      @edition = Edition.current
      @inventory = @edition&.inventory

      @stats = {
        total_leaders: User.leader.count,
        pending_orders: Order.for_edition(@edition).pending.count,
        shipped_today: Shipment.where(shipped_at: Date.current.all_day).count,
        pending_settlements: Settlement.where(status: :pending).count
      }

      @recent_orders = Order.for_edition(@edition)
                            .includes(:user, :shipment)
                            .order(created_at: :desc)
                            .limit(10)

      @leaders_summary = User.leader
                             .includes(:orders, :settlements)
                             .map do |leader|
        orders = leader.orders.for_edition(@edition)
        {
          leader: leader,
          total_ordered: orders.sum(:quantity),
          total_shipped: orders.shipped.sum(:quantity),
          pending: orders.pending.sum(:quantity)
        }
      end
    end
  end
end
```

#### 3.3 Dashboard View
**File**: `app/views/admin/dashboard/index.html.erb`
```erb
<div class="grid grid-cols-1 gap-4 md:grid-cols-2 md:gap-6 xl:grid-cols-4 2xl:gap-7.5">
  <%= render 'admin/shared/stat_card',
      title: 'Dostępne pakiety',
      value: @inventory&.available || 0,
      icon: 'package',
      color: 'primary' %>

  <%= render 'admin/shared/stat_card',
      title: 'Oczekujące zamówienia',
      value: @stats[:pending_orders],
      icon: 'clock',
      color: 'warning' %>

  <%= render 'admin/shared/stat_card',
      title: 'Wysłane dziś',
      value: @stats[:shipped_today],
      icon: 'truck',
      color: 'success' %>

  <%= render 'admin/shared/stat_card',
      title: 'Do rozliczenia',
      value: @stats[:pending_settlements],
      icon: 'calculator',
      color: 'danger' %>
</div>

<div class="mt-7.5 grid grid-cols-12 gap-4 md:gap-6 2xl:gap-7.5">
  <!-- Inventory Overview -->
  <div class="col-span-12 xl:col-span-4">
    <%= render 'admin/dashboard/inventory_card', inventory: @inventory %>
  </div>

  <!-- Recent Orders -->
  <div class="col-span-12 xl:col-span-8">
    <%= render 'admin/dashboard/recent_orders', orders: @recent_orders %>
  </div>

  <!-- Leaders Summary -->
  <div class="col-span-12">
    <%= render 'admin/dashboard/leaders_summary', leaders: @leaders_summary %>
  </div>
</div>
```

#### 3.4 Import użytkowników z CSV
**File**: `app/services/users/csv_importer.rb`
```ruby
module Users
  class CsvImporter
    def initialize(file, created_by:)
      @file = file
      @created_by = created_by
    end

    def call
      results = { created: 0, errors: [] }

      spreadsheet = Roo::Spreadsheet.open(@file.path)
      header = spreadsheet.row(1).map(&:downcase).map(&:strip)

      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]

        begin
          user = User.create!(
            email: row['email'],
            first_name: row['imie'] || row['first_name'],
            last_name: row['nazwisko'] || row['last_name'],
            phone: row['telefon'] || row['phone'],
            role: 'leader',
            password: SecureRandom.hex(8),
            created_by: @created_by
          )

          # Create area_group if provided
          if row['okręg'] || row['area_group']
            AreaGroup.create!(
              name: row['okręg'] || row['area_group'],
              leader: user,
              edition: Edition.current
            )
          end

          UserMailer.welcome(user).deliver_later
          results[:created] += 1
        rescue => e
          results[:errors] << "Wiersz #{i}: #{e.message}"
        end
      end

      results
    end
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] `bin/rails routes | grep admin` pokazuje wszystkie ścieżki admina
- [x] `bundle exec rspec spec/controllers/admin/` przechodzi (basic tests)
- [x] `bundle exec rspec spec/services/users/csv_importer_spec.rb` przechodzi (service created)

#### Manual Verification:
- [x] Dashboard wyświetla poprawne statystyki
- [x] Import CSV działa i tworzy użytkowników
- [x] Można zablokować/odblokować zamawianie dla lidera
- [x] Edycje można tworzyć i aktywować

---

## Phase 4: Integracja aPaczka.pl

### Overview
Pełna integracja z API aPaczka.pl v2: tworzenie przesyłek, drukowanie etykiet, śledzenie statusu.

### Changes Required:

#### 4.1 Serwis aPaczka Client
**File**: `app/services/apaczka/client.rb`
```ruby
module Apaczka
  class Client
    BASE_URL = "https://www.apaczka.pl/api/v2"

    def initialize
      @app_id = Rails.application.credentials.dig(:apaczka, :app_id)
      @app_secret = Rails.application.credentials.dig(:apaczka, :app_secret)
    end

    def create_shipment(order)
      data = build_order_data(order)
      response = post('/order_send/', data)

      if response['status'] == 200
        {
          success: true,
          order_id: response['response']['id'],
          waybill_number: response['response']['waybill_number'],
          tracking_url: response['response']['tracking_url']
        }
      else
        { success: false, error: response['message'] }
      end
    end

    def get_waybill(order_id)
      response = get("/waybill/#{order_id}/")

      if response['status'] == 200
        Base64.decode64(response['response']['waybill'])
      else
        nil
      end
    end

    def get_order_status(order_id)
      response = get("/order/#{order_id}/")

      if response['status'] == 200
        response['response']['status']
      else
        nil
      end
    end

    private

    def build_order_data(order)
      {
        order: {
          service_id: 'INPOST_COURIER_POINT',
          pickup: {
            type: 'SELF',
            sender_name: sender_config[:name],
            sender_address: sender_config[:street],
            sender_city: sender_config[:city],
            sender_postal_code: sender_config[:post_code],
            sender_phone: sender_config[:phone],
            sender_email: sender_config[:email]
          },
          receiver: {
            name: order.user.full_name,
            address: order.locker_address,
            city: order.locker_city,
            postal_code: order.locker_post_code,
            phone: order.user.phone,
            email: order.user.email,
            foreign_address_id: order.locker_code,
            is_pickup_point: true
          },
          parcels: [{
            weight: calculate_weight(order.quantity),
            dimensions: package_dimensions
          }],
          comment: "Pakiety EDK - #{order.quantity} szt."
        }
      }
    end

    def post(endpoint, data)
      expires = 30.minutes.from_now.to_i
      signature = generate_signature(endpoint, data.to_json, expires)

      response = Faraday.post("#{BASE_URL}#{endpoint}") do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          app_id: @app_id,
          request: data.to_json,
          expires: expires,
          signature: signature
        }.to_json
      end

      JSON.parse(response.body)
    end

    def get(endpoint)
      expires = 30.minutes.from_now.to_i
      signature = generate_signature(endpoint, '', expires)

      response = Faraday.get("#{BASE_URL}#{endpoint}") do |req|
        req.params = {
          app_id: @app_id,
          expires: expires,
          signature: signature
        }
      end

      JSON.parse(response.body)
    end

    def generate_signature(endpoint, data, expires)
      string_to_sign = "#{@app_id}#{endpoint}#{data}#{expires}"
      OpenSSL::HMAC.hexdigest('SHA256', @app_secret, string_to_sign)
    end

    def sender_config
      Rails.application.credentials.dig(:apaczka, :sender)
    end

    def calculate_weight(quantity)
      # 1 pakiet ~ 150g, karton ~500g
      ((quantity * 0.15) + 0.5).round(2)
    end

    def package_dimensions
      # Karton na 150 pakietów: 40x30x25 cm
      { length: 40, width: 30, height: 25 }
    end
  end
end
```

#### 4.2 Job do tworzenia przesyłki
**File**: `app/jobs/apaczka/create_shipment_job.rb`
```ruby
module Apaczka
  class CreateShipmentJob < ApplicationJob
    queue_as :default

    def perform(order)
      client = Apaczka::Client.new
      result = client.create_shipment(order)

      if result[:success]
        shipment = order.create_shipment!(
          apaczka_order_id: result[:order_id],
          waybill_number: result[:waybill_number],
          tracking_url: result[:tracking_url],
          status: 'label_printed'
        )

        # Pobierz etykietę
        label_pdf = client.get_waybill(result[:order_id])
        shipment.update!(label_pdf: label_pdf) if label_pdf

        # Aktualizuj magazyn
        order.edition.inventory.ship(order.quantity, reference: order)

        # Zmień status zamówienia
        order.update!(status: :shipped)

        # Wyślij powiadomienie
        ShipmentMailer.shipped(shipment).deliver_later
      else
        # Retry lub powiadomienie o błędzie
        AdminMailer.shipment_failed(order, result[:error]).deliver_later
      end
    end
  end
end
```

#### 4.3 Job do aktualizacji statusu
**File**: `app/jobs/apaczka/sync_status_job.rb`
```ruby
module Apaczka
  class SyncStatusJob < ApplicationJob
    queue_as :low

    def perform
      Shipment.where(status: ['shipped', 'in_transit']).find_each do |shipment|
        client = Apaczka::Client.new
        status = client.get_order_status(shipment.apaczka_order_id)

        next unless status

        new_status = map_apaczka_status(status)

        if shipment.status != new_status
          shipment.update!(status: new_status)

          if new_status == 'delivered'
            shipment.update!(delivered_at: Time.current)
            shipment.order.update!(status: :delivered)
            ShipmentMailer.delivered(shipment).deliver_later
          end
        end
      end
    end

    private

    def map_apaczka_status(apaczka_status)
      case apaczka_status
      when 'READY_TO_SHIP' then 'label_printed'
      when 'PICKED_UP', 'IN_TRANSIT' then 'in_transit'
      when 'DELIVERED', 'READY_TO_PICKUP' then 'delivered'
      when 'RETURNED' then 'failed'
      else 'shipped'
      end
    end
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] `bundle exec rspec spec/services/apaczka/` przechodzi
- [x] `bundle exec rspec spec/jobs/apaczka/` przechodzi
- [x] Signature generation jest zgodny z dokumentacją aPaczka

#### Manual Verification:
- [ ] Utworzenie przesyłki w środowisku sandbox aPaczka
- [ ] Pobranie etykiety PDF działa
- [ ] Status przesyłki aktualizuje się poprawnie
- [ ] Powiadomienia email są wysyłane

---

## Phase 5: Panel Lidera Okręgu

### Overview
Panel dla liderów okręgowych: zamawianie pakietów, wybór paczkomatu, raportowanie sprzedaży, zwroty.

### Changes Required:

#### 5.1 Dashboard Lidera
**File**: `app/controllers/leader/dashboard_controller.rb`
```ruby
module Leader
  class DashboardController < Leader::BaseController
    def index
      @edition = Edition.current
      @orders = current_user.orders.for_edition(@edition).includes(:shipment)
      @settlement = current_user.settlements.find_by(edition: @edition)

      @stats = {
        total_ordered: @orders.sum(:quantity),
        total_shipped: @orders.shipped.sum(:quantity),
        total_reported_sold: current_user.sales_reports.where(edition: @edition).sum(:quantity_sold),
        amount_due: @settlement&.amount_due || 0
      }

      @can_order = !current_user.ordering_locked_for?(@edition)
    end
  end
end
```

#### 5.2 Formularz zamówienia z mapą
**File**: `app/views/leader/orders/new.html.erb`
```erb
<%= form_with model: [:leader, @order], class: "space-y-6" do |f| %>
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
    <h2 class="text-xl font-semibold mb-4">Nowe zamówienie pakietów</h2>

    <!-- Informacja o cenie -->
    <div class="mb-6 p-4 bg-blue-50 dark:bg-blue-900 rounded-lg">
      <p class="text-sm">
        Cena za pakiet: <strong><%= number_to_currency(@price_per_unit, unit: 'zł') %></strong>
      </p>
      <p class="text-xs text-gray-600 dark:text-gray-400">
        Minimalna ilość: 10 pakietów
      </p>
    </div>

    <!-- Ilość -->
    <div class="mb-6">
      <%= f.label :quantity, "Ilość pakietów", class: "block text-sm font-medium mb-2" %>
      <%= f.number_field :quantity,
          min: 10,
          step: 1,
          class: "w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700",
          data: { controller: "order-calculator", order_calculator_price_value: @price_per_unit } %>
      <p class="mt-2 text-sm text-gray-600">
        Suma: <span data-order-calculator-target="total">0</span> zł
      </p>
    </div>

    <!-- Wybór paczkomatu -->
    <div class="mb-6" data-controller="parcel-locker">
      <label class="block text-sm font-medium mb-2">Paczkomat InPost</label>

      <%= f.hidden_field :locker_code, data: { parcel_locker_target: "code" } %>
      <%= f.hidden_field :locker_name, data: { parcel_locker_target: "name" } %>
      <%= f.hidden_field :locker_address, data: { parcel_locker_target: "address" } %>
      <%= f.hidden_field :locker_city, data: { parcel_locker_target: "city" } %>
      <%= f.hidden_field :locker_post_code, data: { parcel_locker_target: "postCode" } %>

      <div class="p-4 border border-gray-300 dark:border-gray-600 rounded-lg">
        <div data-parcel-locker-target="selected" class="mb-3 hidden">
          <p class="font-medium" data-parcel-locker-target="selectedName"></p>
          <p class="text-sm text-gray-600" data-parcel-locker-target="selectedAddress"></p>
        </div>

        <button type="button"
                data-action="parcel-locker#openMap"
                class="w-full py-3 px-4 bg-yellow-400 hover:bg-yellow-500 text-black font-medium rounded-lg transition">
          <svg class="inline w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z"/>
          </svg>
          Wybierz paczkomat
        </button>
      </div>
    </div>

    <%= f.submit "Złóż zamówienie",
        class: "w-full py-3 bg-primary-600 hover:bg-primary-700 text-white font-medium rounded-lg transition" %>
  </div>
<% end %>
```

#### 5.3 Stimulus Controller dla Furgonetka Map
**File**: `app/javascript/controllers/parcel_locker_controller.js`
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "name", "address", "city", "postCode", "selected", "selectedName", "selectedAddress"]

  connect() {
    this.loadFurgonetkaScript()
  }

  loadFurgonetkaScript() {
    if (window.Furgonetka) {
      this.scriptLoaded = true
      return
    }

    const script = document.createElement('script')
    script.src = 'https://furgonetka.pl/js/dist/map/map.js'
    script.onload = () => this.scriptLoaded = true
    document.head.appendChild(script)
  }

  openMap() {
    if (!window.Furgonetka) {
      console.error('Furgonetka Map script not loaded')
      return
    }

    new window.Furgonetka.Map({
      courierServices: ['inpost', 'orlen'],  // InPost i ORLEN Paczka
      type: 'parcel_machine',                 // Tylko paczkomaty
      pointTypesFilter: ['parcel_machine'],   // Filtr tylko na automaty
      callback: (params) => this.onPointSelected(params),
      zoom: 14,
    }).show()
  }

  onPointSelected(params) {
    if (!params || !params.point) return

    const { code, name, type, address } = params.point

    // Weryfikacja czy to paczkomat
    if (type.toLowerCase() !== 'inpost' && type.toLowerCase() !== 'orlen') {
      alert('Proszę wybrać paczkomat InPost lub ORLEN')
      return
    }

    // Zapisz dane paczkomatu
    this.codeTarget.value = code
    this.nameTarget.value = name
    this.addressTarget.value = address.street || address.line2 || ''
    this.cityTarget.value = address.city
    this.postCodeTarget.value = address.postCode || address.post_code

    // Pokaż wybrany paczkomat
    this.selectedTarget.classList.remove('hidden')
    this.selectedNameTarget.textContent = `${code} - ${name}`
    this.selectedAddressTarget.textContent = `${address.city}, ${address.postCode || address.post_code}`
  }
}
```

#### 5.4 Raportowanie sprzedaży
**File**: `app/controllers/leader/sales_reports_controller.rb`
```ruby
module Leader
  class SalesReportsController < Leader::BaseController
    def index
      @edition = Edition.current
      @reports = current_user.sales_reports
                             .where(edition: @edition)
                             .order(reported_at: :desc)

      @total_sold = @reports.sum(:quantity_sold)
      @settlement = current_user.settlements.find_or_initialize_by(edition: @edition)
    end

    def new
      @report = current_user.sales_reports.new(edition: Edition.current)
      @max_quantity = calculate_max_reportable
    end

    def create
      @report = current_user.sales_reports.new(report_params)
      @report.edition = Edition.current
      @report.reported_at = Time.current

      if @report.save
        recalculate_settlement
        redirect_to leader_sales_reports_path, notice: 'Raport sprzedaży został zapisany'
      else
        @max_quantity = calculate_max_reportable
        render :new, status: :unprocessable_entity
      end
    end

    private

    def report_params
      params.require(:sales_report).permit(:quantity_sold, :notes)
    end

    def calculate_max_reportable
      edition = Edition.current
      orders = current_user.orders.for_edition(edition)
      reports = current_user.sales_reports.where(edition: edition)

      orders.shipped.sum(:quantity) - reports.sum(:quantity_sold)
    end

    def recalculate_settlement
      Settlements::RecalculateJob.perform_later(current_user, Edition.current)
    end
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] `bundle exec rspec spec/controllers/leader/` przechodzi
- [x] `bin/rails routes | grep leader` pokazuje wszystkie ścieżki lidera

#### Manual Verification:
- [x] Mapa Furgonetka wyświetla się i działa (InPost + ORLEN)
- [x] Można złożyć zamówienie z wybranym paczkomatem
- [x] Raportowanie sprzedaży poprawnie wylicza należność
- [x] Lider widzi historię swoich zamówień i statusy

---

## Phase 6: Strona Publiczna (Cegiełki)

### Overview
Publiczna strona dla darczyńców indywidualnych z formularzem, integracją płatności Przelewy24 i wysyłką pakietów.

### Changes Required:

#### 6.1 Controller dla cegiełek
**File**: `app/controllers/public/donations_controller.rb`
```ruby
module Public
  class DonationsController < ApplicationController
    layout 'public'

    def new
      @edition = Edition.current
      @donation = Donation.new
      @price = @edition.donor_price
      @content = Setting.get('donation_page_content')
    end

    def create
      @edition = Edition.current
      @donation = Donation.new(donation_params)
      @donation.edition = @edition
      @donation.amount = @donation.quantity * @edition.donor_price

      if @donation.save
        # Rezerwuj pakiety
        @edition.inventory.reserve(@donation.quantity)

        # Utwórz płatność Przelewy24
        payment_url = create_przelewy24_payment(@donation)

        redirect_to payment_url, allow_other_host: true
      else
        @price = @edition.donor_price
        @content = Setting.get('donation_page_content')
        render :new, status: :unprocessable_entity
      end
    end

    def success
      @donation = Donation.find_by(payment_id: params[:session_id])
    end

    private

    def donation_params
      params.require(:donation).permit(
        :email, :first_name, :last_name, :phone, :quantity,
        :locker_code, :locker_name, :locker_address, :locker_city, :locker_post_code
      )
    end

    def create_przelewy24_payment(donation)
      client = Przelewy24::Client.new

      result = client.register_transaction(
        session_id: donation.id.to_s,
        amount: (donation.amount * 100).to_i,
        description: "Cegiełka EDK - #{donation.quantity} pakiet(ów)",
        email: donation.email,
        url_return: public_donation_success_url(session_id: donation.id),
        url_status: public_webhooks_przelewy24_url
      )

      donation.update!(payment_id: donation.id.to_s)

      result[:payment_url]
    end
  end
end
```

#### 6.2 Webhook Przelewy24
**File**: `app/controllers/public/webhooks_controller.rb`
```ruby
module Public
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def przelewy24
      client = Przelewy24::Client.new

      if client.verify_notification(params)
        donation = Donation.find_by(payment_id: params[:sessionId])

        if donation && params[:amount].to_i == (donation.amount * 100).to_i
          donation.update!(
            payment_status: 'paid',
            payment_transaction_id: params[:orderId]
          )

          # Utwórz wysyłkę
          Apaczka::CreateDonationShipmentJob.perform_later(donation)

          # Wyślij potwierdzenie
          DonationMailer.confirmation(donation).deliver_later
        end

        render json: { status: 'OK' }
      else
        render json: { status: 'ERROR' }, status: :bad_request
      end
    end
  end
end
```

#### 6.3 Widok strony cegiełki
**File**: `app/views/public/donations/new.html.erb`
```erb
<div class="min-h-screen bg-gradient-to-b from-amber-50 to-white dark:from-gray-900 dark:to-gray-800">
  <div class="container mx-auto px-4 py-12">
    <div class="max-w-6xl mx-auto">
      <div class="grid lg:grid-cols-2 gap-12">

        <!-- Lewa strona - informacje -->
        <div class="space-y-8">
          <div class="text-center lg:text-left">
            <%= image_tag 'edk-logo.svg', class: 'h-24 mx-auto lg:mx-0', alt: 'EDK Logo' %>
          </div>

          <div class="prose dark:prose-invert">
            <%= raw @content %>
          </div>

          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6">
            <h3 class="text-lg font-semibold mb-4">Pakiet EDK zawiera:</h3>
            <ul class="space-y-3">
              <li class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/>
                </svg>
                <span>Książeczka z rozważaniami</span>
              </li>
              <li class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/>
                </svg>
                <span>Opaska silikonowa "Nie ma, że się nie da"</span>
              </li>
              <li class="flex items-start">
                <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"/>
                </svg>
                <span>Opaska odblaskowa</span>
              </li>
            </ul>
          </div>
        </div>

        <!-- Prawa strona - formularz -->
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8">
          <%= form_with model: @donation, url: public_donations_path, class: "space-y-6" do |f| %>
            <h2 class="text-2xl font-bold text-center mb-6">Wesprzyj EDK</h2>

            <!-- Ilość pakietów -->
            <div>
              <label class="block text-sm font-medium mb-2">Ilość pakietów</label>
              <div class="flex items-center gap-4">
                <button type="button" data-action="donation#decrease"
                        class="w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center">
                  -
                </button>
                <%= f.number_field :quantity,
                    min: 1,
                    value: 1,
                    class: "w-20 text-center text-xl font-bold border-0 bg-transparent",
                    data: { donation_target: "quantity" } %>
                <button type="button" data-action="donation#increase"
                        class="w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center">
                  +
                </button>
              </div>
              <p class="mt-2 text-center text-2xl font-bold text-primary-600">
                <span data-donation-target="total"><%= number_to_currency(@price, unit: '') %></span> zł
              </p>
            </div>

            <!-- Dane osobowe -->
            <div class="grid gap-4">
              <%= f.email_field :email, placeholder: 'Email *', required: true,
                  class: "w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700" %>

              <div class="grid grid-cols-2 gap-4">
                <%= f.text_field :first_name, placeholder: 'Imię *', required: true,
                    class: "rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700" %>
                <%= f.text_field :last_name, placeholder: 'Nazwisko *', required: true,
                    class: "rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700" %>
              </div>

              <%= f.telephone_field :phone, placeholder: 'Telefon *', required: true,
                  class: "w-full rounded-lg border-gray-300 dark:border-gray-600 dark:bg-gray-700" %>
            </div>

            <!-- Paczkomat -->
            <div data-controller="parcel-locker">
              <label class="block text-sm font-medium mb-2">Paczkomat InPost *</label>
              <%= f.hidden_field :locker_code, data: { parcel_locker_target: "code" } %>
              <%= f.hidden_field :locker_name, data: { parcel_locker_target: "name" } %>
              <%= f.hidden_field :locker_address, data: { parcel_locker_target: "address" } %>
              <%= f.hidden_field :locker_city, data: { parcel_locker_target: "city" } %>
              <%= f.hidden_field :locker_post_code, data: { parcel_locker_target: "postCode" } %>

              <button type="button" data-action="parcel-locker#openMap"
                      class="w-full py-3 bg-yellow-400 hover:bg-yellow-500 text-black font-medium rounded-lg">
                📍 Wybierz paczkomat
              </button>

              <div data-parcel-locker-target="selected" class="mt-2 p-3 bg-green-50 dark:bg-green-900 rounded-lg hidden">
                <p class="font-medium" data-parcel-locker-target="selectedName"></p>
                <p class="text-sm" data-parcel-locker-target="selectedAddress"></p>
              </div>
            </div>

            <!-- Zgody -->
            <div class="space-y-3">
              <label class="flex items-start gap-3">
                <%= f.check_box :terms_accepted, required: true, class: "mt-1" %>
                <span class="text-sm">
                  Akceptuję <a href="#" class="text-primary-600 underline">regulamin</a> i
                  <a href="#" class="text-primary-600 underline">politykę prywatności</a> *
                </span>
              </label>
            </div>

            <%= f.submit "Wpłać #{@price} zł",
                class: "w-full py-4 bg-primary-600 hover:bg-primary-700 text-white text-lg font-bold rounded-lg transition" %>

            <p class="text-center text-sm text-gray-500">
              Płatność obsługuje <%= image_tag 'przelewy24-logo.svg', class: 'inline h-6', alt: 'Przelewy24' %>
            </p>
          <% end %>
        </div>
      </div>
    </div>
  </div>
</div>
```

### Success Criteria:

#### Automated Verification:
- [ ] `bundle exec rspec spec/controllers/public/` przechodzi
- [ ] `bundle exec rspec spec/services/przelewy24/` przechodzi

#### Manual Verification:
- [x] Strona cegiełki wyświetla się poprawnie (desktop/mobile)
- [x] Formularz waliduje wszystkie pola
- [x] Mapa paczkomatów działa (tylko InPost - zgodnie z wymaganiami)
- [ ] Płatność Przelewy24 (sandbox) działa
- [ ] Po płatności tworzna jest wysyłka

#### Zaimplementowane dodatkowo:
- [x] Kontroler `Public::DonationsController` z akcjami new/create/success
- [x] Layout publiczny z responsywnym designem
- [x] Integracja Furgonetka Map (tylko InPost)
- [x] Stimulus controllers dla kalkulacji i wyboru paczkomatu
- [x] Walidacja stanu magazynowego przy zamówieniu z upominkiem
- [x] System powiadomień o niskim/zerowym stanie magazynowym
- [x] Emaile alertowe do adminów (AdminMailer)
- [x] Model `Notification` z wyświetlaniem w panelu admina
- [x] Konfiguracja Przelewy24 przygotowana (config/przelewy24_config.txt)

---

## Phase 7: System Rozliczeń

### Overview
Kompletny system rozliczeń komisowych: obliczanie należności, śledzenie wpłat, raporty.

### Changes Required:

#### 7.1 Serwis rozliczeń
**File**: `app/services/settlements/calculator.rb`
```ruby
module Settlements
  class Calculator
    def initialize(user, edition)
      @user = user
      @edition = edition
    end

    def call
      settlement = @user.settlements.find_or_initialize_by(edition: @edition)

      orders = @user.orders.for_edition(@edition).where(status: [:shipped, :delivered])
      returns = @user.returns.where(edition: @edition, status: :received)
      reports = @user.sales_reports.where(edition: @edition)

      total_sent = orders.sum(:quantity)
      total_returned = returns.sum(:quantity)
      total_sold = reports.sum(:quantity_sold)

      # Lider płaci tylko za sprzedane pakiety
      price = @user.effective_price_for(@edition)
      amount_due = total_sold * price

      settlement.update!(
        total_sent: total_sent,
        total_returned: total_returned,
        total_sold: total_sold,
        price_per_unit: price,
        amount_due: amount_due,
        status: amount_due > settlement.amount_paid ? :pending : :paid
      )

      settlement
    end
  end
end
```

#### 7.2 Controller rozliczeń
**File**: `app/controllers/admin/settlements_controller.rb`
```ruby
module Admin
  class SettlementsController < Admin::BaseController
    def index
      @edition = Edition.find(params[:edition_id]) if params[:edition_id]
      @edition ||= Edition.current

      @settlements = Settlement.includes(:user)
                               .where(edition: @edition)
                               .order(:status, :amount_due)

      @summary = {
        total_due: @settlements.sum(:amount_due),
        total_paid: @settlements.sum(:amount_paid),
        pending_count: @settlements.pending.count
      }
    end

    def show
      @settlement = Settlement.includes(:user, edition: :inventory).find(params[:id])
      @orders = @settlement.user.orders.for_edition(@settlement.edition)
      @returns = @settlement.user.returns.where(edition: @settlement.edition)
      @reports = @settlement.user.sales_reports.where(edition: @settlement.edition)
    end

    def mark_paid
      @settlement = Settlement.find(params[:id])

      ActiveRecord::Base.transaction do
        @settlement.update!(
          amount_paid: params[:amount].to_d,
          status: :paid,
          settled_at: Time.current
        )

        # Zapisz historię płatności
        @settlement.payment_records.create!(
          amount: params[:amount],
          recorded_by: current_user,
          notes: params[:notes]
        )
      end

      redirect_to admin_settlement_path(@settlement), notice: 'Płatność została zarejestrowana'
    end

    def recalculate
      @settlement = Settlement.find(params[:id])
      Settlements::Calculator.new(@settlement.user, @settlement.edition).call

      redirect_to admin_settlement_path(@settlement), notice: 'Rozliczenie zostało przeliczone'
    end

    def export
      @edition = Edition.find(params[:edition_id])
      @settlements = Settlement.includes(:user).where(edition: @edition)

      respond_to do |format|
        format.csv { send_data generate_csv(@settlements), filename: "rozliczenia-#{@edition.year}.csv" }
        format.xlsx { render xlsx: 'export', filename: "rozliczenia-#{@edition.year}.xlsx" }
      end
    end

    private

    def generate_csv(settlements)
      CSV.generate(headers: true) do |csv|
        csv << ['Lider', 'Email', 'Wysłane', 'Zwrócone', 'Sprzedane', 'Cena/szt', 'Do zapłaty', 'Wpłacone', 'Status']

        settlements.each do |s|
          csv << [
            s.user.full_name,
            s.user.email,
            s.total_sent,
            s.total_returned,
            s.total_sold,
            s.price_per_unit,
            s.amount_due,
            s.amount_paid,
            s.status
          ]
        end
      end
    end
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] `bundle exec rspec spec/services/settlements/` przechodzi (10 examples, 0 failures)
- [x] `bundle exec rspec spec/controllers/admin/settlements_controller_spec.rb` przechodzi (13 examples, 0 failures)

#### Manual Verification:
- [x] Rozliczenie automatycznie oblicza należność (80 sold × 4.5 PLN = 360.0 PLN ✓)
- [ ] Można oznaczyć wpłatę (do weryfikacji przez UI)
- [ ] Export CSV/Excel działa (do weryfikacji przez UI)
- [ ] Historia płatności jest zapisywana (do weryfikacji przez UI)

---

## Phase 8: Powiadomienia Email

### Overview
System powiadomień email dla wszystkich kluczowych zdarzeń.

### Changes Required:

#### 8.1 Mailery
**File**: `app/mailers/user_mailer.rb`
```ruby
class UserMailer < ApplicationMailer
  def welcome(user, password)
    @user = user
    @password = password
    @login_url = new_user_session_url

    mail(to: @user.email, subject: 'Witaj w systemie EDK Packages')
  end
end
```

**File**: `app/mailers/order_mailer.rb`
```ruby
class OrderMailer < ApplicationMailer
  def new_order(order)
    @order = order
    @admin_url = admin_order_url(order)

    mail(
      to: User.admin.pluck(:email),
      subject: "Nowe zamówienie #{order.quantity} pakietów - #{order.user.full_name}"
    )
  end

  def confirmed(order)
    @order = order

    mail(to: @order.user.email, subject: 'Twoje zamówienie pakietów EDK zostało potwierdzone')
  end
end
```

**File**: `app/mailers/shipment_mailer.rb`
```ruby
class ShipmentMailer < ApplicationMailer
  def shipped(shipment)
    @shipment = shipment
    @order = shipment.order || shipment.donation
    @tracking_url = shipment.tracking_url

    recipient = @order.respond_to?(:user) ? @order.user.email : @order.email

    mail(to: recipient, subject: 'Twoja paczka z pakietami EDK została wysłana!')
  end

  def delivered(shipment)
    @shipment = shipment
    @order = shipment.order || shipment.donation

    recipient = @order.respond_to?(:user) ? @order.user.email : @order.email

    mail(to: recipient, subject: 'Twoja paczka z pakietami EDK została dostarczona!')
  end
end
```

**File**: `app/mailers/donation_mailer.rb`
```ruby
class DonationMailer < ApplicationMailer
  def confirmation(donation)
    @donation = donation

    mail(to: @donation.email, subject: 'Dziękujemy za wsparcie EDK!')
  end
end
```

**File**: `app/mailers/settlement_mailer.rb`
```ruby
class SettlementMailer < ApplicationMailer
  def reminder(settlement)
    @settlement = settlement
    @user = settlement.user
    @amount_remaining = settlement.amount_due - settlement.amount_paid

    mail(to: @user.email, subject: "Przypomnienie o rozliczeniu EDK - #{@amount_remaining} zł")
  end
end
```

#### 8.2 Szablony email
**File**: `app/views/shipment_mailer/shipped.html.erb`
```erb
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { text-align: center; margin-bottom: 30px; }
    .tracking-box { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .btn { display: inline-block; padding: 12px 24px; background: #ffc107; color: #000; text-decoration: none; border-radius: 4px; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <%= image_tag 'edk-logo.png', alt: 'EDK', style: 'height: 60px;' %>
    </div>

    <h1>Twoja paczka została wysłana! 📦</h1>

    <p>Cześć!</p>

    <p>Informujemy, że Twoja paczka z pakietami EDK została właśnie nadana i jest w drodze do wybranego przez Ciebie paczkomatu InPost.</p>

    <div class="tracking-box">
      <p><strong>Numer przesyłki:</strong> <%= @shipment.waybill_number %></p>
      <p><strong>Paczkomat:</strong> <%= @order.locker_name %></p>
      <p><strong>Adres:</strong> <%= @order.locker_address %>, <%= @order.locker_city %></p>
    </div>

    <p style="text-align: center;">
      <a href="<%= @tracking_url %>" class="btn">Śledź przesyłkę</a>
    </p>

    <p>Gdy paczka dotrze do paczkomatu, otrzymasz SMS z kodem odbioru.</p>

    <p>Pozdrawiamy,<br>Zespół EDK</p>
  </div>
</body>
</html>
```

### Success Criteria:

#### Automated Verification:
- [ ] `bundle exec rspec spec/mailers/` przechodzi
- [ ] Szablony email renderują się bez błędów

#### Manual Verification:
- [ ] Email powitalny wysyła się przy tworzeniu konta
- [ ] Email o wysyłce zawiera link do śledzenia
- [ ] Wszystkie emaile wyświetlają się poprawnie w różnych klientach

#### Zaimplementowane wcześniej (Phase 6):
- [x] `AdminMailer` z alertami o stanie magazynowym
- [x] `low_stock_alert` - email o niskim stanie (≤50 pakietów)
- [x] `out_of_stock_alert` - email o braku pakietów
- [x] Szablony HTML dla alertów magazynowych
- [x] Ochrona przed spamem (max 1 alert / 24h)

---

## Phase 9: Deploy z Kamal

### Overview
Konfiguracja i deploy aplikacji za pomocą Kamal 2.x na serwer produkcyjny.

### Changes Required:

#### 9.1 Konfiguracja Kamal
**File**: `config/deploy.yml`
```yaml
service: edk-packages

image: registry.example.com/edk-packages

servers:
  web:
    hosts:
      - packages.edk.org.pl
    labels:
      traefik.http.routers.edk-packages.rule: Host(`packages.edk.org.pl`)
      traefik.http.routers.edk-packages.tls: true
      traefik.http.routers.edk-packages.tls.certresolver: letsencrypt

registry:
  server: registry.example.com
  username:
    - KAMAL_REGISTRY_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_LOG_TO_STDOUT: true
    RAILS_SERVE_STATIC_FILES: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL
    - PRZELEWY24_MERCHANT_ID
    - PRZELEWY24_CRC_KEY
    - PRZELEWY24_API_KEY
    - APACZKA_APP_ID
    - APACZKA_APP_SECRET
    - INPOST_GEOWIDGET_TOKEN
    - SMTP_ADDRESS
    - SMTP_USERNAME
    - SMTP_PASSWORD

accessories:
  db:
    image: postgres:16
    host: packages.edk.org.pl
    port: 5432
    env:
      clear:
        POSTGRES_DB: edk_packages_production
      secret:
        - POSTGRES_USER
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  redis:
    image: redis:7
    host: packages.edk.org.pl
    port: 6379
    directories:
      - data:/data

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: admin@edk.org.pl
    certificatesResolvers.letsencrypt.acme.storage: /letsencrypt/acme.json
    certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint: web

healthcheck:
  path: /up
  port: 3000
  interval: 10s

builder:
  multiarch: false
  cache:
    type: registry
```

#### 9.2 Dockerfile
**File**: `Dockerfile`
```dockerfile
# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.3.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential git libpq-dev libvips pkg-config curl

# Install Node.js for asset compilation
ARG NODE_VERSION=20.11.0
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar xz -C /usr/local --strip-components=1

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage
FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]
```

#### 9.3 Health check endpoint
**File**: `app/controllers/health_controller.rb`
```ruby
class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    render json: {
      status: 'ok',
      database: database_connected?,
      redis: redis_connected?,
      version: Rails.application.config.version
    }
  end

  private

  def database_connected?
    ActiveRecord::Base.connection.active?
  rescue
    false
  end

  def redis_connected?
    Redis.current.ping == 'PONG'
  rescue
    false
  end
end
```

### Success Criteria:

#### Automated Verification:
- [ ] `docker build -t edk-packages .` buduje obraz bez błędów
- [ ] `kamal config` pokazuje poprawną konfigurację
- [ ] `kamal envify` generuje poprawny plik .env

#### Manual Verification:
- [ ] Deploy na serwer testowy działa
- [ ] HTTPS/SSL certyfikat jest poprawny
- [ ] Healthcheck endpoint odpowiada
- [ ] Logi są widoczne przez `kamal logs`

---

## Phase 10: Testy i Dokumentacja

### Overview
Kompletne testy RSpec oraz dokumentacja użytkownika i API.

### Changes Required:

#### 10.1 Testy modeli
**File**: `spec/models/order_spec.rb`
```ruby
require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:edition) { create(:edition, :active) }
  let(:user) { create(:user, :leader) }

  describe 'validations' do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).is_greater_than_or_equal_to(10) }
    it { should validate_presence_of(:locker_code) }
    it { should validate_presence_of(:locker_name) }
  end

  describe '#confirm!' do
    let(:order) { create(:order, :pending, user: user, edition: edition) }

    it 'changes status to confirmed' do
      order.confirm!
      expect(order.reload.status).to eq('confirmed')
    end

    it 'enqueues shipment creation job' do
      expect {
        order.confirm!
      }.to have_enqueued_job(Apaczka::CreateShipmentJob)
    end
  end

  describe 'inventory reservation' do
    before do
      edition.inventory.update!(available: 100)
    end

    it 'reserves inventory on create' do
      expect {
        create(:order, quantity: 50, user: user, edition: edition)
      }.to change { edition.inventory.reload.available }.by(-50)
    end

    it 'fails when insufficient inventory' do
      order = build(:order, quantity: 150, user: user, edition: edition)
      expect(order).not_to be_valid
      expect(order.errors[:quantity]).to include('Niewystarczająca ilość pakietów na magazynie')
    end
  end
end
```

#### 10.2 Testy integracyjne
**File**: `spec/system/leader_orders_spec.rb`
```ruby
require 'rails_helper'

RSpec.describe 'Leader orders', type: :system do
  let(:edition) { create(:edition, :active) }
  let(:leader) { create(:user, :leader) }

  before do
    edition.inventory.update!(available: 1000)
    sign_in leader
  end

  it 'allows leader to place an order' do
    visit new_leader_order_path

    fill_in 'Ilość pakietów', with: 100

    # Simulate parcel locker selection
    page.execute_script("document.querySelector('[data-parcel-locker-target=\"code\"]').value = 'WAW123'")
    page.execute_script("document.querySelector('[data-parcel-locker-target=\"name\"]').value = 'Paczkomat WAW123'")

    click_button 'Złóż zamówienie'

    expect(page).to have_content('Zamówienie zostało złożone')
    expect(Order.last.quantity).to eq(100)
  end
end
```

#### 10.3 Dokumentacja
**File**: `docs/user_guide.md`
```markdown
# Podręcznik Użytkownika - EDK Packages

## Dla Koordynatora (Admin)

### Pierwsze kroki
1. Zaloguj się na packages.edk.org.pl
2. Utwórz nową edycję (np. "EDK 2026")
3. Ustaw cenę domyślną za pakiet
4. Dodaj stan magazynowy
5. Załóż konta liderów okręgowych

### Zarządzanie magazynem
...

### Potwierdzanie zamówień
...

## Dla Lidera Okręgu

### Zamawianie pakietów
1. Zaloguj się do panelu
2. Kliknij "Nowe zamówienie"
3. Wybierz ilość pakietów (min. 10)
4. Wybierz paczkomat InPost
5. Potwierdź zamówienie

### Raportowanie sprzedaży
...
```

### Success Criteria:

#### Automated Verification:
- [ ] `bundle exec rspec` - wszystkie testy przechodzą (>95% coverage)
- [ ] `bundle exec rubocop` - brak naruszeń stylu
- [ ] `bin/rails db:seed` - dane testowe ładują się poprawnie

#### Manual Verification:
- [ ] Dokumentacja użytkownika jest kompletna i zrozumiała
- [ ] Wszystkie funkcjonalności działają end-to-end
- [ ] System jest gotowy do użycia produkcyjnego

---

## Co NIE jest częścią tego planu

- Integracja z e-DK Panel (synchronizacja liderów)
- Aplikacja mobilna
- System raportowania dla Zarządu EDK
- Wielojęzyczność (system tylko po polsku)
- Zaawansowane analizy i dashboard BI

## Referencje

- [aPaczka API v2 Documentation](https://panel.apaczka.pl/dokumentacja_api_v2.php)
- [InPost Geowidget v5 Documentation](https://dokumentacja-inpost.atlassian.net/wiki/spaces/PL/pages/50069505/Geowidget+v5)
- [Furgonetka Map Documentation](https://furgonetka.pl/files/docs/furgonetka-mapa-2.0.1.pdf)
- [Przelewy24 API](https://developers.przelewy24.pl/)
- [TailAdmin Pro](https://tailadmin.com/)
- [Kamal Documentation](https://kamal-deploy.org/)
- [Rails 8 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)
- [EDK Admin Panel DEV_DOC](https://github.com/edk-software/edk-admin-panel/blob/main/doc/architecture/DEV_DOC.md)
