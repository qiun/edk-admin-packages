# Plan Implementacji - Publiczna Strona Cegiełek

## Przegląd

Implementacja publicznej strony cegiełek dla darczyńców indywidualnych w projekcie edk-admin-packages (Ruby on Rails). Strona wzorowana na istniejącej implementacji z https://wspieram.edk.org.pl/cegielka (projekt edk-donations-refactor w Next.js).

### Funkcjonalności
- Formularz darowizny z wyborem ilości pakietów (50 zł/szt)
- Dane osobowe: email, tytuł, imię, nazwisko, telefon
- Checkbox "Chcę otrzymać upominek" - jeśli zaznaczony, pokazuje mapę paczkomatów
- Integracja Furgonetka Map (wybór paczkomatu InPost/ORLEN)
- Integracja płatności Przelewy24
- Webhook do potwierdzenia płatności
- Automatyczne tworzenie wysyłki przez aPaczka

### Wzór interfejsu (z edk-donations-refactor)

**Layout strony:**
- Two-column layout na desktop (lg:flex-row)
- Lewa kolumna (białe tło): Header z logo, opis, lista powodów
- Prawa kolumna (szare tło): Formularz

**Header:**
- Logo EDK 2025 (obrazek)
- Nagłówek "Cegiełka" / "na EDK" (font Bangers, kolor indigo-600)
- Lista powodów wsparcia

**Formularz:**
- Sekcja ilości: Pole ilości + cena (50 PLN) + suma
- Dane osobowe: Email, Tytuł (select), Imię, Nazwisko, Telefon
- Checkbox "Chcę otrzymać upominek" z opisem
- Mapa Furgonetka (po zaznaczeniu checkboxa)
- Zgody: Checkbox regulaminu
- Przycisk "Wpłać teraz" (indigo-600)

**Kolorystyka:**
- Główny kolor: indigo-600 (#4F46E5)
- Tło formularza: white / gray-100
- Dark mode: gray-700, gray-800, gray-900

---

## Phase 1: Podstawowa Struktura i Routing

### Overview
Utworzenie struktury plików, routingu i podstawowego layoutu dla strony cegiełek.

### Changes Required:

#### 1.1 Routing
**File**: `config/routes.rb` (dodanie do istniejącego)
```ruby
# Public donation page
scope module: 'public' do
  get 'cegielka', to: 'donations#new', as: :public_donation
  post 'cegielka', to: 'donations#create', as: :public_donation_create
  get 'cegielka/sukces', to: 'donations#success', as: :public_donation_success
  get 'cegielka/blad', to: 'donations#error', as: :public_donation_error
  
  # Webhooks
  post 'webhooks/przelewy24', to: 'webhooks#przelewy24'
end
```

#### 1.2 Public Base Controller
**File**: `app/controllers/public/base_controller.rb`

#### 1.3 Donations Controller
**File**: `app/controllers/public/donations_controller.rb`

#### 1.4 Public Layout
**File**: `app/views/layouts/public.html.erb`
- Font Poppins + Bangers z Google Fonts
- Responsywny layout

### Success Criteria:
- [ ] `bin/rails routes | grep cegielka` pokazuje ścieżki publiczne
- [ ] Strona `/cegielka` renderuje się bez błędów

---

## Phase 2: Layout i Header Strony

### Overview
Implementacja two-column layoutu i headera z logo i opisem.

### Changes Required:

#### 2.1 Główny widok formularza
**File**: `app/views/public/donations/new.html.erb`
- Two-column layout (białe/szare tło)
- Lewa kolumna: header + sekcja ilości
- Prawa kolumna: formularz osobowy + upominek + zgody + submit

#### 2.2 Header partial
**File**: `app/views/public/donations/_header.html.erb`
- Logo EDK 2025 (obrazek z zaokrąglonymi rogami)
- Nagłówek "Cegiełka" / "na EDK" (font Bangers)
- Lista powodów wsparcia:
  - EDK to dom dla idealistów. Dołóż cegiełkę, bo warto.
  - Idealiści chodzą na EDK, potem zmienią siebie, i wreszcie świat.
  - Twoja cegiełka ma znaczenie!!! Bez niej niczego nie zbudujemy.
  - Cegiełka to darowizna na EDK w wysokości 50 zł.
  - Uwaga - informacja o upominku

### Success Criteria:
- [ ] Header wyświetla logo i nagłówek w stylu Bangers
- [ ] Two-column layout działa na desktop
- [ ] Responsywny layout na mobile (jedna kolumna)

---

## Phase 3: Sekcje Formularza

### Overview
Implementacja wszystkich sekcji formularza: ilość, dane osobowe, upominek, zgody.

### Changes Required:

#### 3.1 Sekcja ilości
**File**: `app/views/public/donations/_amount_section.html.erb`
- Box z ceną 50 PLN i polem ilości
- Kalkulator sumy (quantity × 50)
- Tooltip "Ilość" na hover

#### 3.2 Dane osobowe
**File**: `app/views/public/donations/_personal_info.html.erb`
- Email (wymagane)
- Tytuł - select: Pan, Pani, Ksiądz, Siostra, Ojciec, Brat (wymagane)
- Imię, Nazwisko (wymagane)
- Telefon (wymagane jeśli want_gift)

#### 3.3 Sekcja upominku (z mapą Furgonetka)
**File**: `app/views/public/donations/_gift_section.html.erb`
- Checkbox "Chcę otrzymać upominek za darowiznę"
- Opis: "W ramach wdzięczności za Twoją cegiełkę możesz odebrać pamiątkowy pakiet EDK"
- Animowane pokazywanie/ukrywanie sekcji paczkomatu
- Przycisk "Wybierz paczkomat InPost lub ORLEN Paczka"
- Hidden fields: locker_code, locker_name, locker_address, locker_city, locker_post_code
- Wyświetlanie wybranego paczkomatu

#### 3.4 Sekcja zgód
**File**: `app/views/public/donations/_terms_section.html.erb`
- Checkbox akceptacji regulaminu
- Link do regulaminu

#### 3.5 Przycisk submit
**File**: `app/views/public/donations/_submit_button.html.erb`
- "Wpłać teraz" (indigo-600 z hover effect)
- Link do regulaminu Przelewy24

#### 3.6 Footer
**File**: `app/views/public/donations/_footer.html.erb`
- Dane Fundacji Indywidualności Otwartych
- KRS, NIP, REGON
- Link do kontaktu

### Success Criteria:
- [ ] Wszystkie sekcje formularza są widoczne
- [ ] Pola wyświetlają błędy walidacji
- [ ] Layout responsywny działa poprawnie

---

## Phase 4: Stimulus Controller i Furgonetka Map

### Overview
Implementacja Stimulus controller do obsługi formularza i integracji z mapą Furgonetka.

### Changes Required:

#### 4.1 Stimulus Controller
**File**: `app/javascript/controllers/donation_form_controller.js`

**Funkcjonalności:**
- `connect()` - ładowanie skryptu Furgonetka
- `updateTotal()` - aktualizacja sumy (quantity × price)
- `toggleGiftSection()` - pokazywanie/ukrywanie sekcji paczkomatu
- `openFurgonetkaMap()` - otwieranie mapy Furgonetka
- `onPointSelected(params)` - obsługa wybranego paczkomatu
- `handleSubmit(event)` - walidacja przed wysłaniem

**Targets:**
- quantity, total, wantGift, giftSection, phoneRequired
- lockerCode, lockerName, lockerAddress, lockerCity, lockerPostCode
- selectedLocker, submitButton

**Konfiguracja mapy Furgonetka:**
```javascript
new window.Furgonetka.Map({
  courierServices: ['inpost', 'orlen'],
  type: 'parcel_machine',
  pointTypesFilter: ['parcel_machine'],
  callback: (params) => this.onPointSelected(params),
  zoom: 14,
}).show()
```

#### 4.2 Rejestracja controllera
**File**: `app/javascript/controllers/index.js`

### Success Criteria:
- [ ] Mapa Furgonetka otwiera się po kliknięciu przycisku
- [ ] Wybór paczkomatu aktualizuje hidden fields
- [ ] Suma aktualizuje się przy zmianie ilości
- [ ] Sekcja upominku pokazuje/ukrywa się przy checkbox

---

## Phase 5: Integracja Przelewy24

### Overview
Implementacja klienta Przelewy24 do obsługi płatności i webhook.

### Changes Required:

#### 5.1 Przelewy24 Client
**File**: `app/services/przelewy24/client.rb`

**Metody:**
- `register_transaction(session_id:, amount:, description:, email:, url_return:, url_status:)`
- `verify_transaction(session_id:, order_id:, amount:)`
- `verify_notification(params)` - weryfikacja podpisu webhook

**Credentials (config/credentials.yml.enc):**
```yaml
przelewy24:
  merchant_id: "xxx"
  pos_id: "xxx"
  crc_key: "xxx"
  api_key: "xxx"
  sandbox: true
```

#### 5.2 Webhooks Controller
**File**: `app/controllers/public/webhooks_controller.rb`

**Flow webhook:**
1. Weryfikacja podpisu
2. Znalezienie darowizny po session_id
3. Sprawdzenie kwoty
4. Weryfikacja transakcji z Przelewy24
5. Aktualizacja statusu płatności
6. Utworzenie wysyłki (jeśli want_gift)
7. Wysłanie emaila potwierdzającego

### Success Criteria:
- [ ] Płatność w sandbox Przelewy24 działa
- [ ] Webhook aktualizuje status płatności
- [ ] Email potwierdzający jest wysyłany

---

## Phase 6: Model Donation i Walidacje

### Overview
Aktualizacja modelu Donation o nowe pola i walidacje.

### Changes Required:

#### 6.1 Migracja - dodanie pól
**File**: `db/migrate/xxx_add_gift_fields_to_donations.rb`
```ruby
add_column :donations, :title, :string
add_column :donations, :want_gift, :boolean, default: false
add_column :donations, :terms_accepted, :boolean, default: false
```

#### 6.2 Aktualizacja modelu
**File**: `app/models/donation.rb`

**Walidacje:**
- email: presence, format
- title: presence, inclusion (MR, MRS, PRIEST, SISTER, FATHER, BROTHER)
- first_name, last_name: presence, max 100 znaków
- quantity: presence, numericality > 0
- terms_accepted: acceptance
- phone: presence if want_gift
- locker_code, locker_name: presence if want_gift

### Success Criteria:
- [ ] `bin/rails db:migrate` działa
- [ ] Walidacje działają w konsoli

---

## Phase 7: Strony Sukcesu i Błędu

### Overview
Implementacja stron po płatności.

### Changes Required:

#### 7.1 Strona sukcesu
**File**: `app/views/public/donations/success.html.erb`
- Gradient zielony
- Ikona sukcesu (checkmark)
- "Dziękujemy za Twoje wsparcie!"
- Szczegóły wysyłki (jeśli want_gift)
- Przycisk "Wróć na stronę EDK"

#### 7.2 Strona błędu
**File**: `app/views/public/donations/error.html.erb`
- Gradient czerwony
- Ikona błędu (X)
- "Wystąpił problem z płatnością"
- Przyciski: "Spróbuj ponownie", "Kontakt"

### Success Criteria:
- [ ] Strona sukcesu wyświetla szczegóły
- [ ] Strona błędu oferuje opcje kontaktu

---

## Phase 8: Email Potwierdzający

### Overview
Implementacja emaila z potwierdzeniem płatności.

### Changes Required:

#### 8.1 Mailer
**File**: `app/mailers/donation_mailer.rb`
- `confirmation(donation)` - email potwierdzający

#### 8.2 Szablon email
**File**: `app/views/donation_mailer/confirmation.html.erb`
- Header z gradientem indigo
- Powitanie z imieniem
- Szczegóły darowizny (ilość, kwota, data)
- Szczegóły wysyłki (jeśli want_gift)
- Hasło "Nie ma, że się nie da!"
- Footer z danymi fundacji

### Success Criteria:
- [ ] Email wysyła się po potwierdzeniu płatności
- [ ] Email zawiera wszystkie szczegóły

---

## Phase 9: Job do Tworzenia Wysyłki

### Overview
Job do automatycznego tworzenia wysyłki przez aPaczka.

### Changes Required:

#### 9.1 Job
**File**: `app/jobs/apaczka/create_donation_shipment_job.rb`

**Flow:**
1. Sprawdzenie czy want_gift i locker_code
2. Sprawdzenie czy nie ma już wysyłki
3. Wywołanie `client.create_shipment_for_donation(donation)`
4. Utworzenie rekordu Shipment
5. Pobranie etykiety PDF
6. Aktualizacja magazynu (inventory.ship)
7. Wysłanie emaila z numerem przesyłki

#### 9.2 Aktualizacja klienta aPaczka
**File**: `app/services/apaczka/client.rb`
- Dodanie metody `create_shipment_for_donation(donation)`
- Metoda `build_donation_order_data(donation)`

### Success Criteria:
- [ ] Wysyłka tworzy się automatycznie po płatności
- [ ] Etykieta jest pobierana
- [ ] Email z numerem przesyłki jest wysyłany

---

## Phase 10: Testy i Dokumentacja

### Overview
Testy i dokumentacja dla strony cegiełek.

### Changes Required:

#### 10.1 Testy request
**File**: `spec/requests/public/donations_spec.rb`
- GET /cegielka - renders form
- POST /cegielka - creates donation and redirects to payment
- POST /cegielka - renders errors for invalid data

#### 10.2 Testy modelu
**File**: `spec/models/donation_spec.rb`
- Walidacje
- Asocjacje

### Success Criteria:
- [ ] `bundle exec rspec spec/requests/public/` przechodzi
- [ ] Pełny flow cegiełki działa end-to-end
- [ ] Strona jest responsywna
- [ ] Dark mode działa

---

## Podsumowanie

### Pliki do utworzenia:
1. `app/controllers/public/base_controller.rb`
2. `app/controllers/public/donations_controller.rb`
3. `app/controllers/public/webhooks_controller.rb`
4. `app/views/layouts/public.html.erb`
5. `app/views/public/donations/new.html.erb`
6. `app/views/public/donations/_header.html.erb`
7. `app/views/public/donations/_amount_section.html.erb`
8. `app/views/public/donations/_personal_info.html.erb`
9. `app/views/public/donations/_gift_section.html.erb`
10. `app/views/public/donations/_terms_section.html.erb`
11. `app/views/public/donations/_submit_button.html.erb`
12. `app/views/public/donations/_footer.html.erb`
13. `app/views/public/donations/success.html.erb`
14. `app/views/public/donations/error.html.erb`
15. `app/javascript/controllers/donation_form_controller.js`
16. `app/services/przelewy24/client.rb`
17. `app/mailers/donation_mailer.rb`
18. `app/views/donation_mailer/confirmation.html.erb`
19. `app/jobs/apaczka/create_donation_shipment_job.rb`
20. `db/migrate/xxx_add_gift_fields_to_donations.rb`

### Pliki do modyfikacji:
1. `config/routes.rb` - dodanie ścieżek publicznych
2. `app/models/donation.rb` - walidacje i nowe pola
3. `app/services/apaczka/client.rb` - metoda dla donation
4. `app/javascript/controllers/index.js` - rejestracja controllera

### Assety do dodania:
1. `app/assets/images/edk-logo-2025.jpg` - logo EDK
