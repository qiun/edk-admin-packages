# Force Password Change on First Login - Implementation Plan

## Overview

Implementacja wymuszenia zmiany hasła przy pierwszym logowaniu użytkownika. Admin nie będzie nadawał haseł - system będzie wysyłał email z linkiem do ustawienia hasła. Hasło musi spełniać wymagania bezpieczeństwa (min 8 znaków, złożoność).

## Current State Analysis

### Obecna implementacja:
- **Devise modules**: `database_authenticatable, recoverable, rememberable, validatable`
- **Password length**: 6-128 znaków (bez walidacji złożoności)
- **Admin user creation**: Formularz z polami password/password_confirmation
- **CSV import**: Hasło generowane losowo (`SecureRandom.hex(8)`)
- **Email**: UserMailer wysyła email z hasłem w plaintexcie

### Problemy:
1. Admin nadaje hasła użytkownikom (niezgodne z best practices)
2. Hasło wysyłane w plaintexcie w emailu (ryzyko bezpieczeństwa)
3. Brak wymuszenia zmiany hasła przy pierwszym logowaniu
4. Brak walidacji złożoności hasła

### Key Files:
- `app/models/user.rb:5-6` - Devise modules
- `app/controllers/admin/users_controller.rb:30-44` - User creation
- `app/services/user_csv_importer.rb:30-45` - CSV import
- `app/views/admin/users/_form.html.erb:83-138` - Password fields
- `config/initializers/devise.rb:181` - Password length config

## Desired End State

1. **Admin NIE nadaje haseł** - pola hasła usunięte z formularza
2. **Email z linkiem** - zamiast hasła w plaintexcie, email zawiera link do ustawienia hasła
3. **Wymuszenie zmiany hasła** - przy pierwszym logowaniu przekierowanie do formularza zmiany hasła
4. **Walidacja złożoności** - min 8 znaków, wielka litera, mała litera, cyfra

### Verification:
- Nowy użytkownik otrzymuje email z linkiem do ustawienia hasła
- Przy próbie logowania bez ustawionego hasła - odpowiedni komunikat
- Po ustawieniu hasła użytkownik może się normalnie logować
- Hasło musi spełniać wymagania bezpieczeństwa

## What We're NOT Doing

- Nie implementujemy password expiration (wygasanie hasła)
- Nie implementujemy password history (historia haseł)
- Nie włączamy Devise :confirmable module
- Nie zmieniamy flow dla istniejących użytkowników
- Nie implementujemy account locking

## Implementation Approach

Zamiast tworzyć hasło tymczasowe i wymuszać zmianę, wykorzystamy istniejący mechanizm Devise `:recoverable` (password reset). Przy tworzeniu użytkownika:
1. Generujemy random token jako hasło (użytkownik go nie zna)
2. Generujemy reset_password_token
3. Wysyłamy email z linkiem do ustawienia hasła (jak przy "Zapomniałem hasła")

To podejście:
- Wykorzystuje istniejący, przetestowany mechanizm Devise
- Nie wymaga dodatkowych pól w bazie
- Hasło nigdy nie jest wysyłane w plaintexcie
- Link wygasa po 6 godzinach (już skonfigurowane)

---

## Phase 1: Password Complexity Validation

### Overview
Dodanie walidacji złożoności hasła: min 8 znaków, wielka litera, mała litera, cyfra.

### Changes Required:

#### 1. Devise Configuration - Password Length
**File**: `config/initializers/devise.rb`
**Changes**: Zmiana minimalnej długości hasła na 8

```ruby
# Line 181 - change from 6 to 8
config.password_length = 8..128
```

#### 2. Devise Configuration - Token Expiration
**File**: `config/initializers/devise.rb`
**Changes**: Zmiana czasu ważności tokenu z 6h na 24h

```ruby
# Line 227 - change from 6.hours to 24.hours
config.reset_password_within = 24.hours
```

#### 3. User Model - Password Complexity Validator
**File**: `app/models/user.rb`
**Changes**: Dodanie custom walidacji złożoności hasła

```ruby
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # NOTE: Removed :registerable - only admins can create user accounts
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  # Password complexity validation
  validate :password_complexity, if: :password_required?

  # Enums
  enum :role, { leader: "leader", warehouse: "warehouse", admin: "admin" }

  # ... existing associations and validations ...

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/[A-Z]/)
      errors.add(:password, "musi zawierać co najmniej jedną wielką literę")
    end

    unless password.match?(/[a-z]/)
      errors.add(:password, "musi zawierać co najmniej jedną małą literę")
    end

    unless password.match?(/\d/)
      errors.add(:password, "musi zawierać co najmniej jedną cyfrę")
    end
  end

  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end
end
```

#### 4. Update Password Reset View Placeholder
**File**: `app/views/devise/passwords/edit.html.erb`
**Changes**: Zmiana placeholdera z "Minimum 6 znaków" na wymagania

```erb
<%= f.password_field :password,
    autofocus: true,
    autocomplete: "new-password",
    placeholder: "Min. 8 znaków, wielka i mała litera, cyfra",
    class: "..." %>
```

### Success Criteria:

#### Automated Verification:
- [x] Rails console: `User.new(email: 'test@test.pl', password: 'short', password_confirmation: 'short', first_name: 'Test', last_name: 'User').valid?` returns `false`
- [x] Rails console: `User.new(email: 'test@test.pl', password: 'Password1', password_confirmation: 'Password1', first_name: 'Test', last_name: 'User').valid?` returns `true`
- [x] Rails console: `User.new(email: 'test@test.pl', password: 'password1', password_confirmation: 'password1', first_name: 'Test', last_name: 'User').valid?` returns `false` (brak wielkiej litery)
- [x] All tests pass: `bin/rails test` or `bundle exec rspec`

#### Manual Verification:
- [ ] Przy resecie hasła, słabe hasło (np. "password") jest odrzucone z komunikatem
- [ ] Przy resecie hasła, silne hasło (np. "Password123") jest akceptowane

**Implementation Note**: Po zakończeniu tej fazy poczekaj na potwierdzenie przed przejściem do następnej.

---

## Phase 2: Remove Password Fields from Admin Form

### Overview
Usunięcie pól hasła z formularza tworzenia użytkownika przez admina.

### Changes Required:

#### 1. Admin Users Form
**File**: `app/views/admin/users/_form.html.erb`
**Changes**: Usunięcie całej sekcji password dla nowych użytkowników (linie 83-109)

Zamień sekcję:
```erb
<%# For new users - password is required %>
<% if user.new_record? %>
  <div class="rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-white/[0.03]">
    ... password fields ...
  </div>
<% end %>
```

Na:
```erb
<%# For new users - password will be set via email link %>
<% if user.new_record? %>
  <div class="rounded-2xl border border-blue-200 bg-blue-50 dark:border-blue-800 dark:bg-blue-900/20 p-5">
    <div class="flex items-start gap-3">
      <svg class="h-6 w-6 text-blue-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <div>
        <h4 class="text-sm font-medium text-blue-800 dark:text-blue-200">Hasło zostanie ustawione przez użytkownika</h4>
        <p class="mt-1 text-sm text-blue-700 dark:text-blue-300">
          Po utworzeniu konta, użytkownik otrzyma email z linkiem do ustawienia własnego hasła.
          Link będzie ważny przez 24 godziny.
        </p>
      </div>
    </div>
  </div>
<% end %>
```

### Success Criteria:

#### Automated Verification:
- [x] Formularz `/admin/users/new` nie zawiera pól `password` ani `password_confirmation`
- [x] All tests pass: `bin/rails test` or `bundle exec rspec`

#### Manual Verification:
- [ ] Otwórz `/admin/users/new` - brak pól hasła
- [ ] Widoczna informacja o wysłaniu emaila z linkiem

**Implementation Note**: Po zakończeniu tej fazy poczekaj na potwierdzenie przed przejściem do następnej.

---

## Phase 3: Update User Creation Logic

### Overview
Zmiana logiki tworzenia użytkownika - generowanie reset token i wysyłanie emaila z linkiem zamiast hasła.

### Changes Required:

#### 1. Admin Users Controller
**File**: `app/controllers/admin/users_controller.rb`
**Changes**: Zmiana metody `create` - użycie reset password token

```ruby
def create
  @user = User.new(user_params)
  @user.created_by = current_user

  # Generate a random password (user won't know it)
  # They will set their own password via the email link
  random_password = SecureRandom.hex(16)
  @user.password = random_password
  @user.password_confirmation = random_password

  if @user.save
    # Generate password reset token and send email
    raw_token, enc_token = Devise.token_generator.generate(User, :reset_password_token)
    @user.reset_password_token = enc_token
    @user.reset_password_sent_at = Time.current
    @user.save(validate: false)

    # Send welcome email with password setup link
    UserMailer.welcome_with_password_setup(@user, raw_token).deliver_later

    redirect_to admin_user_path(@user), notice: "Użytkownik został utworzony. Email z linkiem do ustawienia hasła został wysłany na: #{@user.email}"
  else
    render :new, status: :unprocessable_entity
  end
end
```

#### 2. User Params - Remove Password
**File**: `app/controllers/admin/users_controller.rb`
**Changes**: Usunięcie password z permitted params dla create (zostawić dla update)

```ruby
def user_params
  if action_name == 'create'
    params.require(:user).permit(:email, :first_name, :last_name, :phone, :role)
  else
    params.require(:user).permit(:email, :first_name, :last_name, :phone, :role, :password, :password_confirmation)
  end
end
```

#### 3. UserMailer - New Method
**File**: `app/mailers/user_mailer.rb`
**Changes**: Dodanie nowej metody `welcome_with_password_setup`

```ruby
# Send welcome email with password setup link
# @param user [User] the user record
# @param token [String] raw reset password token
def welcome_with_password_setup(user, token)
  @user = user
  @password_setup_url = edit_user_password_url(reset_password_token: token)

  mail(
    to: @user.email,
    subject: "Witaj w systemie EDK Packages - Ustaw swoje hasło"
  )
end
```

#### 4. New Email Template
**File**: `app/views/user_mailer/welcome_with_password_setup.html.erb`
**Changes**: Nowy template z linkiem do ustawienia hasła

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #5d1655 0%, #8b2380 100%); color: white; padding: 30px; border-radius: 12px 12px 0 0; text-align: center; }
    .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 12px 12px; }
    .button { display: inline-block; background: #5d1655; color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0; }
    .button:hover { background: #8b2380; }
    .info-box { background: #e8f4fd; border-left: 4px solid #5d1655; padding: 15px; margin: 20px 0; }
    .warning { color: #dc2626; font-size: 14px; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; }
  </style>
</head>
<body>
  <div class="header">
    <h1>👋 Witaj w systemie EDK Packages!</h1>
  </div>

  <div class="content">
    <p>Cześć <strong><%= @user.first_name %></strong>!</p>

    <p>Twoje konto w systemie EDK Packages zostało utworzone. Aby się zalogować, musisz najpierw ustawić swoje hasło.</p>

    <div class="info-box">
      <h3>🔐 Twoje dane do logowania</h3>
      <p><strong>Email:</strong> <%= @user.email %></p>
      <p><strong>Hasło:</strong> Ustaw klikając przycisk poniżej</p>
    </div>

    <p style="text-align: center;">
      <a href="<%= @password_setup_url %>" class="button">Ustaw swoje hasło</a>
    </p>

    <p class="warning">
      <strong>⚠️ Ważne:</strong> Link jest ważny przez 24 godziny. Jeśli wygaśnie, skontaktuj się z administratorem lub użyj opcji "Zapomniałem hasła" na stronie logowania.
    </p>

    <h3>📋 Wymagania dotyczące hasła</h3>
    <ul>
      <li>Minimum 8 znaków</li>
      <li>Co najmniej jedna wielka litera (A-Z)</li>
      <li>Co najmniej jedna mała litera (a-z)</li>
      <li>Co najmniej jedna cyfra (0-9)</li>
    </ul>

    <h3>📋 Co możesz zrobić w systemie?</h3>
    <ul>
      <li>Zamawiać pakiety EDK dla swojego okręgu</li>
      <li>Śledzić status zamówień i wysyłek</li>
      <li>Zgłaszać zwroty pakietów</li>
      <li>Zarządzać rozliczeniami</li>
    </ul>

    <p>W razie pytań skontaktuj się z nami: <a href="mailto:pakiety@edk.org.pl">pakiety@edk.org.pl</a></p>
  </div>

  <div class="footer">
    <p><strong>Fundacja Indywidualności Otwartych</strong></p>
    <p>pakiety@edk.org.pl</p>
  </div>
</body>
</html>
```

### Success Criteria:

#### Automated Verification:
- [x] Tworzenie użytkownika przez formularz admin tworzy rekord z reset_password_token
- [x] Email jest kolejkowany do wysłania
- [x] All tests pass: `bin/rails test` or `bundle exec rspec`

#### Manual Verification:
- [ ] Utwórz nowego użytkownika przez `/admin/users/new`
- [ ] Użytkownik otrzymuje email z linkiem
- [ ] Link prowadzi do formularza ustawienia hasła
- [ ] Po ustawieniu hasła użytkownik może się zalogować

**Implementation Note**: Po zakończeniu tej fazy poczekaj na potwierdzenie przed przejściem do następnej.

---

## Phase 4: Update CSV Import Logic

### Overview
Zmiana logiki importu CSV - wysyłanie emaili z linkami zamiast haseł w plaintexcie.

### Changes Required:

#### 1. User CSV Importer
**File**: `app/services/user_csv_importer.rb`
**Changes**: Użycie reset token zamiast hasła tymczasowego

```ruby
require "csv"

class UserCsvImporter
  def initialize(file, created_by:)
    @file = file
    @created_by = created_by
  end

  def call
    result = { created: 0, skipped: 0, errors: [] }

    CSV.foreach(@file.path, headers: true, col_sep: detect_separator) do |row|
      import_row(row, result)
    end

    result
  end

  private

  def import_row(row, result)
    email = row["email"]&.strip&.downcase
    return result[:errors] << "Brak email w wierszu" if email.blank?

    if User.exists?(email: email)
      result[:skipped] += 1
      return
    end

    # Generate random password (user won't know it)
    random_password = SecureRandom.hex(16)

    user = User.new(
      email: email,
      first_name: row["first_name"]&.strip || row["imię"]&.strip,
      last_name: row["last_name"]&.strip || row["nazwisko"]&.strip,
      phone: row["phone"]&.strip || row["telefon"]&.strip,
      role: :leader,
      created_by: @created_by,
      password: random_password,
      password_confirmation: random_password
    )

    if user.save
      result[:created] += 1

      # Generate password reset token
      raw_token, enc_token = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token = enc_token
      user.reset_password_sent_at = Time.current
      user.save(validate: false)

      # Send welcome email with password setup link
      UserMailer.welcome_with_password_setup(user, raw_token).deliver_later
    else
      result[:errors] << "#{email}: #{user.errors.full_messages.join(', ')}"
    end
  end

  def detect_separator
    first_line = File.open(@file.path, &:readline)
    first_line.include?(";") ? ";" : ","
  rescue StandardError
    ","
  end
end
```

### Success Criteria:

#### Automated Verification:
- [x] Import CSV tworzy użytkowników z reset_password_token
- [x] Emaile są kolejkowane dla każdego zaimportowanego użytkownika
- [x] All tests pass: `bin/rails test` or `bundle exec rspec`

#### Manual Verification:
- [ ] Przygotuj CSV z kilkoma użytkownikami
- [ ] Zaimportuj przez `/admin/users/import`
- [ ] Każdy użytkownik otrzymuje email z linkiem
- [ ] Linki działają - pozwalają ustawić hasło

**Implementation Note**: Po zakończeniu tej fazy poczekaj na potwierdzenie przed przejściem do następnej.

---

## Phase 5: Cleanup Old Welcome Email

### Overview
Usunięcie starego emaila welcome z hasłem w plaintexcie.

### Changes Required:

#### 1. Remove Old Welcome Method
**File**: `app/mailers/user_mailer.rb`
**Changes**: Usunięcie lub oznaczenie jako deprecated metody `welcome`

```ruby
# frozen_string_literal: true

# Mailer for user account-related emails (primarily for leaders)
class UserMailer < ApplicationMailer
  default from: ENV.fetch("LEADER_EMAIL_FROM", "pakiety@edk.org.pl")

  # Send welcome email with password setup link
  # @param user [User] the user record
  # @param token [String] raw reset password token
  def welcome_with_password_setup(user, token)
    @user = user
    @password_setup_url = edit_user_password_url(reset_password_token: token)

    mail(
      to: @user.email,
      subject: "Witaj w systemie EDK Packages - Ustaw swoje hasło"
    )
  end

  # Send password reset instructions
  # @param user [User] the user record
  # @param reset_url [String] password reset URL
  def password_reset(user, reset_url)
    @user = user
    @reset_url = reset_url

    mail(
      to: @user.email,
      subject: "Instrukcje resetowania hasła - EDK Packages"
    )
  end
end
```

#### 2. Remove Old Welcome Template
**File**: `app/views/user_mailer/welcome.html.erb`
**Changes**: Usunąć plik (lub zachować jeśli potrzebny z innych powodów)

### Success Criteria:

#### Automated Verification:
- [x] No references to `UserMailer.welcome` in codebase (except tests)
- [x] All tests pass: `bin/rails test` or `bundle exec rspec`

#### Manual Verification:
- [x] Przejrzyj kod - brak wywołań `UserMailer.welcome`

---

## Testing Strategy

### Unit Tests:
- Walidacja złożoności hasła (różne przypadki: za krótkie, brak wielkiej litery, brak cyfry, poprawne)
- UserCsvImporter generuje reset token
- Admin controller generuje reset token

### Integration Tests:
- Pełny flow: admin tworzy użytkownika → email wysłany → użytkownik ustawia hasło → logowanie
- Import CSV → email dla każdego → użytkownicy mogą ustawić hasła

### Manual Testing Steps:
1. Zaloguj się jako admin
2. Utwórz nowego użytkownika przez formularz
3. Sprawdź email (mailcatcher/letter_opener)
4. Kliknij link w emailu
5. Ustaw hasło spełniające wymagania
6. Zaloguj się na nowe konto
7. Powtórz test dla CSV import

## Performance Considerations

- Emaile wysyłane przez `deliver_later` - nie blokują requestu
- Przy dużym imporcie CSV, rozważyć batch processing emaili
- Token generation jest szybki (SecureRandom + Devise)
- Link ważny 24h - wystarczająco długo, ale nie za długo dla bezpieczeństwa

## Migration Notes

- **Istniejący użytkownicy**: Nie są dotknięci zmianami (mają już hasła)
- **Nowi użytkownicy**: Będą musieli ustawić hasło przez email
- **Rollback**: Jeśli trzeba cofnąć, wystarczy przywrócić stary kod (brak migracji DB)

## References

- Devise documentation: https://github.com/heartcombo/devise
- `app/models/user.rb` - User model
- `app/controllers/admin/users_controller.rb` - User creation controller
- `app/services/user_csv_importer.rb` - CSV import service
- `config/initializers/devise.rb` - Devise configuration
