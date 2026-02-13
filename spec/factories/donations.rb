FactoryBot.define do
  factory :donation do
    association :edition

    first_name { "Anna" }
    last_name { "Nowak" }
    sequence(:email) { |n| "donor#{n}@example.com" }
    phone { "601234567" }
    quantity { 1 }
    terms_accepted { true }
    want_gift { false }

    trait :with_gift do
      want_gift { true }
      locker_code { "KRA#{Faker::Number.number(digits: 3)}" }
      locker_name { "Paczkomat #{locker_code}" }
      locker_address { Faker::Address.street_address }
      locker_city { Faker::Address.city }
      locker_post_code { "#{Faker::Number.number(digits: 2)}-#{Faker::Number.number(digits: 3)}" }
    end

    trait :paid do
      payment_status { :paid }
    end

    trait :failed do
      payment_status { :failed }
    end
  end
end
