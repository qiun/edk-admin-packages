FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123" }
    password_confirmation { "Password123" }
    first_name { "Jan" }
    last_name { "Kowalski" }
    role { :leader }

    trait :admin do
      role { :admin }
      first_name { "Admin" }
    end

    trait :warehouse do
      role { :warehouse }
      first_name { "Magazyn" }
    end

    trait :leader do
      role { :leader }
      first_name { "Lider" }
    end
  end
end
