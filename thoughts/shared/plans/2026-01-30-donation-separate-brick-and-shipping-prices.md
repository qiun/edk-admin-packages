# Rozdzielenie ceny cegiełki i wysyłki - Plan Implementacji

## Overview

Wprowadzenie rozdzielenia ceny cegiełki od kosztu wysyłki w systemie darowizn dla darczyńców indywidualnych. Obecnie mamy jedną cenę `donor_price` (50 zł). Po zmianie będą dwa pola:
- **Cena cegiełki** (np. 30 zł) - pobierana za każdą sztukę
- **Koszt wysyłki** (np. 20 zł) - pobierany raz, niezależnie od ilości

## Current State Analysis

### Obecna struktura cenowa:
- Pole `donor_price` w tabeli `editions` (domyślnie 50 zł)
- Formuła: `total = quantity × donor_price`
- Przykład: 2 cegiełki = 2 × 50 = 100 zł

### Nowa struktura cenowa:
- Pole `donor_brick_price` (cena za cegiełkę, np. 30 zł)
- Pole `donor_shipping_cost` (koszt wysyłki, np. 20 zł)
- Formuła: `total = donor_shipping_cost + (quantity × donor_brick_price)`
- Przykłady:
  - 1 cegiełka = 20 + (1 × 30) = **50 zł**
  - 2 cegiełki = 20 + (2 × 30) = **80 zł**
  - 3 cegiełki = 20 + (3 × 30) = **110 zł**
  - 4 cegiełki = 20 + (4 × 30) = **140 zł**

### Key Discoveries:
- Kalkulacja ceny odbywa się w 3 miejscach:
  - [donations_controller.rb:15](app/controllers/public/donations_controller.rb#L15) - kontroler (server-side)
  - [donation.rb:39](app/models/donation.rb#L39) - model (callback before_create)
  - [donation_form_controller.js:36](app/javascript/controllers/donation_form_controller.js#L36) - JavaScript (client-side)
- Panel admin edycji: [_form.html.erb:117-132](app/views/admin/editions/_form.html.erb#L117-L132)
- Schemat DB: [schema.rb:58](db/schema.rb#L58)

## Desired End State

Po implementacji:
1. W panelu Admin w formularzu edycji będą **dwa osobne pola**:
   - "Cena cegiełki dla darczyńców" (donor_brick_price)
   - "Koszt wysyłki dla darczyńców" (donor_shipping_cost)
2. Na stronie `/cegielka` cena będzie obliczana wg nowej formuły
3. Wyświetlana będzie informacja o rozbiciu ceny (np. "Cegiełka: 30 zł + Wysyłka: 20 zł")
4. Migracja danych: obecne `donor_price` zostanie przekonwertowane na nowe pola z rozsądnymi wartościami domyślnymi

## What We're NOT Doing

- Nie zmieniamy systemu cen dla liderów (default_price)
- Nie zmieniamy innych funkcjonalności strony cegiełki
- Nie modyfikujemy historycznych danych w tabeli donations (pozostają jako kwota całkowita)

## Implementation Approach

1. Dodajemy nowe pole `donor_shipping_cost` do tabeli editions
2. Zmieniamy nazwę `donor_price` na `donor_brick_price` dla jasności
3. Aktualizujemy wszystkie miejsca kalkulacji (kontroler, model, JS)
4. Aktualizujemy widoki (admin form, strona cegiełki)

---

## Phase 1: Migracja bazy danych

### Overview
Dodanie nowej kolumny `donor_shipping_cost` i zmiana nazwy `donor_price` na `donor_brick_price`.

### Changes Required:

#### 1. Migracja bazy danych
**File**: `db/migrate/XXXXXXXX_add_donor_shipping_cost_to_editions.rb`

```ruby
class AddDonorShippingCostToEditions < ActiveRecord::Migration[7.0]
  def up
    # Dodaj nowe pole dla kosztu wysyłki
    add_column :editions, :donor_shipping_cost, :decimal, precision: 8, scale: 2, default: 20.0, null: false

    # Zmień nazwę donor_price na donor_brick_price dla jasności
    rename_column :editions, :donor_price, :donor_brick_price

    # Ustaw domyślną wartość dla istniejących edycji
    # Zakładamy: stara cena 50 zł = 30 zł cegiełka + 20 zł wysyłka
    Edition.reset_column_information
    Edition.find_each do |edition|
      # Jeśli poprzednia cena była 50, ustaw 30 za cegiełkę + 20 za wysyłkę
      if edition.donor_brick_price == 50
        edition.update_columns(donor_brick_price: 30.0, donor_shipping_cost: 20.0)
      else
        # Dla innych wartości, odejmij 20 od ceny jako przybliżenie
        new_brick_price = [edition.donor_brick_price - 20, 10].max
        edition.update_columns(donor_brick_price: new_brick_price, donor_shipping_cost: 20.0)
      end
    end
  end

  def down
    # Przy rollback, połącz wartości z powrotem
    Edition.reset_column_information
    Edition.find_each do |edition|
      combined_price = edition.donor_brick_price + edition.donor_shipping_cost
      edition.update_columns(donor_brick_price: combined_price)
    end

    rename_column :editions, :donor_brick_price, :donor_price
    remove_column :editions, :donor_shipping_cost
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] Migracja działa: `bin/rails db:migrate`
- [x] Rollback działa: `bin/rails db:rollback && bin/rails db:migrate`
- [x] Schema zawiera nowe kolumny: `grep -E "donor_brick_price|donor_shipping_cost" db/schema.rb`

#### Manual Verification:
- [ ] W bazie istnieją prawidłowe wartości dla istniejących edycji

**Implementation Note**: Po zakończeniu tej fazy i weryfikacji automatycznej, poczekaj na potwierdzenie przed przejściem do następnej fazy.

---

## Phase 2: Model Edition

### Overview
Aktualizacja modelu Edition - dodanie walidacji i pomocniczych metod.

### Changes Required:

#### 1. Model Edition
**File**: `app/models/edition.rb`

Zmienić walidację (linia 19):
```ruby
# FROM:
validates :donor_price, presence: true, numericality: { greater_than: 0 }

# TO:
validates :donor_brick_price, presence: true, numericality: { greater_than: 0 }
validates :donor_shipping_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
```

Dodać metodę pomocniczą do obliczania ceny:
```ruby
# Oblicza całkowitą cenę dla danej ilości cegiełek
def calculate_donor_total(quantity)
  donor_shipping_cost + (quantity * donor_brick_price)
end

# Zwraca cenę pierwszej cegiełki (z wysyłką)
def donor_first_brick_price
  donor_brick_price + donor_shipping_cost
end
```

### Success Criteria:

#### Automated Verification:
- [x] Testy modelu przechodzą: `bin/rails test test/models/edition_test.rb` lub `bundle exec rspec spec/models/edition_spec.rb`
- [x] Rails console działa: `Edition.current.calculate_donor_total(3)` zwraca poprawną wartość

#### Manual Verification:
- [ ] Walidacja działa w konsoli Rails

---

## Phase 3: Panel Admin - Formularz Edition

### Overview
Aktualizacja formularza edycji w panelu admina - dodanie pola dla kosztu wysyłki i zmiana etykiet.

### Changes Required:

#### 1. Formularz edycji
**File**: `app/views/admin/editions/_form.html.erb`

Zmienić sekcję "Cennik" (linie 116-133) na:

```erb
<div class="grid grid-cols-1 gap-6 sm:grid-cols-2">
  <div>
    <%= f.label :default_price, "Cena dla liderów", class: "mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400" %>
    <div class="relative">
      <%= f.number_field :default_price,
        min: 0,
        step: 0.01,
        class: "shadow-theme-xs focus:border-brand-300 focus:ring-brand-500/10 dark:focus:border-brand-800 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 pr-12 text-sm text-gray-800 placeholder:text-gray-400 focus:ring-3 focus:outline-hidden dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30",
        placeholder: "30.00",
        required: true %>
      <span class="pointer-events-none absolute top-1/2 right-4 -translate-y-1/2 text-sm text-gray-500 dark:text-gray-400">
        zł
      </span>
    </div>
    <p class="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
      Domyślna cena za pakiet dla liderów obszarowych
    </p>
  </div>

  <div>
    <%= f.label :donor_brick_price, "Cena cegiełki dla darczyńców", class: "mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400" %>
    <div class="relative">
      <%= f.number_field :donor_brick_price,
        min: 0,
        step: 0.01,
        class: "shadow-theme-xs focus:border-brand-300 focus:ring-brand-500/10 dark:focus:border-brand-800 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 pr-12 text-sm text-gray-800 placeholder:text-gray-400 focus:ring-3 focus:outline-hidden dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30",
        placeholder: "30.00",
        required: true %>
      <span class="pointer-events-none absolute top-1/2 right-4 -translate-y-1/2 text-sm text-gray-500 dark:text-gray-400">
        zł
      </span>
    </div>
    <p class="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
      Cena za pojedynczą cegiełkę (bez wysyłki)
    </p>
  </div>

  <div>
    <%= f.label :donor_shipping_cost, "Koszt wysyłki dla darczyńców", class: "mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400" %>
    <div class="relative">
      <%= f.number_field :donor_shipping_cost,
        min: 0,
        step: 0.01,
        class: "shadow-theme-xs focus:border-brand-300 focus:ring-brand-500/10 dark:focus:border-brand-800 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 pr-12 text-sm text-gray-800 placeholder:text-gray-400 focus:ring-3 focus:outline-hidden dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30",
        placeholder: "20.00",
        required: true %>
      <span class="pointer-events-none absolute top-1/2 right-4 -translate-y-1/2 text-sm text-gray-500 dark:text-gray-400">
        zł
      </span>
    </div>
    <p class="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
      Jednorazowy koszt wysyłki (doliczany raz, niezależnie od ilości)
    </p>
  </div>
</div>

<!-- Pricing Preview -->
<div class="mt-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
  <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Podgląd cen dla darczyńców:</h4>
  <div class="text-xs text-gray-600 dark:text-gray-400 space-y-1" id="pricing-preview">
    <p>1 cegiełka: <strong><%= @edition.donor_brick_price + @edition.donor_shipping_cost %> zł</strong> (cegiełka + wysyłka)</p>
    <p>2 cegiełki: <strong><%= (@edition.donor_brick_price * 2) + @edition.donor_shipping_cost %> zł</strong></p>
    <p>3 cegiełki: <strong><%= (@edition.donor_brick_price * 3) + @edition.donor_shipping_cost %> zł</strong></p>
  </div>
</div>
```

#### 2. Kontroler Admin Editions
**File**: `app/controllers/admin/editions_controller.rb`

Zmienić `edition_params` (linia 68):
```ruby
# FROM:
params.require(:edition).permit(:name, :year, :status, :default_price, :donor_price, :ordering_locked, :check_donation_inventory)

# TO:
params.require(:edition).permit(:name, :year, :status, :default_price, :donor_brick_price, :donor_shipping_cost, :ordering_locked, :check_donation_inventory)
```

#### 3. Widok szczegółów edycji (opcjonalnie)
**File**: `app/views/admin/editions/show.html.erb`

Jeśli wyświetla `donor_price`, zmienić na wyświetlanie obu nowych pól.

### Success Criteria:

#### Automated Verification:
- [x] Aplikacja startuje bez błędów: `bin/rails server`
- [x] Formularz renderuje się bez błędów

#### Manual Verification:
- [ ] W formularzu edycji widoczne są dwa pola: "Cena cegiełki" i "Koszt wysyłki"
- [ ] Zapisywanie wartości działa poprawnie
- [ ] Podgląd cen pokazuje prawidłowe wartości

---

## Phase 4: Strona publiczna - Kalkulacja ceny

### Overview
Aktualizacja kontrolera, modelu i widoków strony cegiełki.

### Changes Required:

#### 1. Kontroler Public::DonationsController
**File**: `app/controllers/public/donations_controller.rb`

```ruby
module Public
  class DonationsController < Public::BaseController
    def new
      @donation = Donation.new(quantity: 1, want_gift: true)
      @edition = current_edition
      @brick_price = @edition&.donor_brick_price || 30.0
      @shipping_cost = @edition&.donor_shipping_cost || 20.0
    end

    def create
      @edition = current_edition
      @brick_price = @edition&.donor_brick_price || 30.0
      @shipping_cost = @edition&.donor_shipping_cost || 20.0

      @donation = Donation.new(donation_params)
      @donation.edition = @edition
      # Nowa formuła: wysyłka + (ilość × cena_cegiełki)
      @donation.amount = @shipping_cost + (@donation.quantity.to_i * @brick_price)
      @donation.payment_id = generate_payment_id
      @donation.payment_status = "pending"

      # ... reszta metody bez zmian
    end

    # ... reszta kontrolera bez zmian
  end
end
```

#### 2. Model Donation
**File**: `app/models/donation.rb`

Zmienić metodę `calculate_amount` (linia 38-40):
```ruby
def calculate_amount
  brick_price = edition&.donor_brick_price || 30
  shipping_cost = edition&.donor_shipping_cost || 20
  self.amount = shipping_cost + (quantity * brick_price)
end
```

#### 3. Widok główny strony cegiełki
**File**: `app/views/public/donations/new.html.erb`

Zmienić atrybuty data dla kontrolera Stimulus (linia 3):
```erb
<main data-controller="donation-form"
      data-donation-form-brick-price-value="<%= @brick_price %>"
      data-donation-form-shipping-cost-value="<%= @shipping_cost %>">
```

#### 4. Partial z ceną
**File**: `app/views/public/donations/_amount_section.html.erb`

Zmienić na przekazywanie obu cen:
```erb
<%# locals: (f:, donation:, brick_price:, shipping_cost:) %>
<div class="border-t border-gray-300 pt-6">
  <label class="block text-sm font-medium text-gray-900 mb-3">
    Wybierz cegiełkę <span class="text-[#5d1655]">*</span>
  </label>

  <!-- Brick Selection Box -->
  <div class="border border-gray-300 rounded-lg p-4 bg-white">
    <div class="flex items-center justify-between">
      <span class="font-medium text-gray-900">Cegiełka EDK</span>
      <div class="flex items-center gap-4">
        <span class="font-semibold text-[#5d1655]"><%= number_to_currency(brick_price, unit: '', precision: 0) %> zł/szt</span>
        <%= f.number_field :quantity,
            min: 1,
            value: donation.quantity || 1,
            class: "w-16 text-center border border-gray-300 rounded-md py-2 px-2 text-sm focus:ring-2 focus:ring-[#5d1655] focus:border-[#5d1655] outline-none",
            data: { donation_form_target: "quantity", action: "input->donation-form#updateTotal" } %>
      </div>
    </div>

    <!-- Shipping info -->
    <div class="mt-2 pt-2 border-t border-gray-200">
      <div class="flex items-center justify-between text-sm text-gray-600">
        <span>Wysyłka (jednorazowo)</span>
        <span class="font-medium"><%= number_to_currency(shipping_cost, unit: '', precision: 0) %> zł</span>
      </div>
    </div>
  </div>

  <% if donation.errors[:quantity].present? %>
    <p class="text-xs text-red-600 mt-1"><%= donation.errors[:quantity].first %></p>
  <% end %>

  <!-- Total -->
  <div class="text-right mt-3 text-sm font-semibold text-gray-700">
    Razem: <span data-donation-form-target="total"><%= number_to_currency(shipping_cost + ((donation.quantity || 1) * brick_price), unit: '', precision: 0) %></span> zł
  </div>

  <!-- Price breakdown -->
  <div class="text-right mt-1 text-xs text-gray-500">
    (<span data-donation-form-target="quantityDisplay"><%= donation.quantity || 1 %></span> × <%= number_to_currency(brick_price, unit: '', precision: 0) %> zł + <%= number_to_currency(shipping_cost, unit: '', precision: 0) %> zł wysyłki)
  </div>
</div>
```

#### 5. Aktualizacja wywołania partiala
**File**: `app/views/public/donations/new.html.erb`

Zmienić wywołanie partiala:
```erb
<%= render "public/donations/amount_section", f: f, donation: @donation, brick_price: @brick_price, shipping_cost: @shipping_cost %>
```

### Success Criteria:

#### Automated Verification:
- [x] Aplikacja startuje bez błędów
- [x] Testy kontrolera przechodzą (jeśli istnieją)

#### Manual Verification:
- [ ] Na stronie `/cegielka` widać cenę cegiełki i koszt wysyłki osobno
- [ ] Dla 1 cegiełki suma = 50 zł (przy ustawieniach 30+20)
- [ ] Dla 2 cegiełek suma = 80 zł
- [ ] Dla 3 cegiełek suma = 110 zł

---

## Phase 5: JavaScript - Dynamiczna kalkulacja

### Overview
Aktualizacja kontrolera Stimulus do obsługi nowej formuły cenowej.

### Changes Required:

#### 1. Kontroler Stimulus
**File**: `app/javascript/controllers/donation_form_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "quantity", "total", "quantityDisplay", "wantGift", "giftSection",
    "lockerCode", "lockerName", "lockerAddress", "lockerCity", "lockerPostCode",
    "selectedLocker", "submitButton"
  ]

  static values = {
    brickPrice: { type: Number, default: 30 },
    shippingCost: { type: Number, default: 20 }
  }

  connect() {
    this.loadFurgonetkaScript()
    this.updateTotal()
  }

  loadFurgonetkaScript() {
    if (window.Furgonetka) {
      this.scriptLoaded = true
      return
    }

    const script = document.createElement('script')
    script.src = 'https://furgonetka.pl/js/dist/map/map.js'
    script.onload = () => { this.scriptLoaded = true }
    script.onerror = () => { console.error('Failed to load Furgonetka map script') }
    document.head.appendChild(script)
  }

  updateTotal() {
    if (!this.hasQuantityTarget || !this.hasTotalTarget) return

    const quantity = parseInt(this.quantityTarget.value) || 1
    // Nowa formuła: wysyłka + (ilość × cena_cegiełki)
    const total = this.shippingCostValue + (quantity * this.brickPriceValue)
    this.totalTarget.textContent = total

    // Aktualizuj wyświetlaną ilość w rozbicu ceny
    if (this.hasQuantityDisplayTarget) {
      this.quantityDisplayTarget.textContent = quantity
    }
  }

  // ... reszta metod bez zmian (toggleGiftSection, openFurgonetkaMap, onPointSelected, handleSubmit)
}
```

### Success Criteria:

#### Automated Verification:
- [x] Build JavaScript przechodzi bez błędów: `bin/rails assets:precompile`

#### Manual Verification:
- [ ] Na stronie `/cegielka` zmiana ilości dynamicznie przelicza sumę
- [ ] Dla 1: 50 zł, dla 2: 80 zł, dla 3: 110 zł
- [ ] Suma wyświetla się poprawnie

---

## Phase 6: Testy i weryfikacja

### Overview
Dodanie/aktualizacja testów i końcowa weryfikacja całego przepływu.

### Changes Required:

#### 1. Factory (jeśli używane)
**File**: `spec/factories/editions.rb` lub `test/factories/editions.rb`

```ruby
FactoryBot.define do
  factory :edition do
    name { "EDK #{Time.current.year}" }
    year { Time.current.year }
    status { :active }
    default_price { 30.0 }
    donor_brick_price { 30.0 }
    donor_shipping_cost { 20.0 }
  end
end
```

#### 2. Test modelu Edition
**File**: `spec/models/edition_spec.rb` lub `test/models/edition_test.rb`

```ruby
describe "donor pricing" do
  let(:edition) { create(:edition, donor_brick_price: 30, donor_shipping_cost: 20) }

  it "calculates total for single brick" do
    expect(edition.calculate_donor_total(1)).to eq(50)
  end

  it "calculates total for multiple bricks" do
    expect(edition.calculate_donor_total(3)).to eq(110)
  end

  it "returns first brick price with shipping" do
    expect(edition.donor_first_brick_price).to eq(50)
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] Wszystkie testy przechodzą: `bin/rails test` lub `bundle exec rspec`
- [x] Linting przechodzi: `bundle exec rubocop` (jeśli używane)

#### Manual Verification:
- [ ] Pełny przepływ: Utwórz edycję → Ustaw ceny → Otwórz /cegielka → Wybierz ilość → Sprawdź sumę
- [ ] Płatność Przelewy24 otrzymuje prawidłową kwotę

---

## Testing Strategy

### Unit Tests:
- Model Edition: `calculate_donor_total`, `donor_first_brick_price`
- Model Donation: `calculate_amount` z nową formułą

### Integration Tests:
- Formularz darowizny: prawidłowa kalkulacja przy różnych ilościach
- Płatność: prawidłowa kwota wysyłana do Przelewy24

### Manual Testing Steps:
1. Zaloguj się do panelu admin
2. Edytuj edycję - ustaw cenę cegiełki: 30 zł, wysyłkę: 20 zł
3. Otwórz stronę `/cegielka`
4. Sprawdź czy wyświetla się cena 50 zł dla 1 cegiełki
5. Zmień ilość na 2 - sprawdź czy suma = 80 zł
6. Zmień ilość na 3 - sprawdź czy suma = 110 zł
7. Wypełnij formularz i przejdź do płatności
8. Sprawdź czy kwota w Przelewy24 jest prawidłowa

## Migration Notes

- Migracja automatycznie konwertuje istniejące dane
- Dla edycji z `donor_price = 50`, zostanie ustawione: `donor_brick_price = 30`, `donor_shipping_cost = 20`
- Historyczne darowizny (tabela donations) pozostają bez zmian - kwoty były już zapisane jako total

## References

- Obecna dokumentacja systemu: [2026-01-22-edk-package-coordinator-system.md](thoughts/shared/plans/2026-01-22-edk-package-coordinator-system.md)
- Model Edition: [edition.rb](app/models/edition.rb)
- Kontroler darowizn: [donations_controller.rb](app/controllers/public/donations_controller.rb)
- Formularz admin: [_form.html.erb](app/views/admin/editions/_form.html.erb)
