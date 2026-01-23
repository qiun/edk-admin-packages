FactoryBot.define do
  factory :order do
    association :user, factory: :user, role: :leader
    association :edition

    quantity { 10 }
    status { :pending }
    locker_code { "KRA#{Faker::Number.number(digits: 3)}" }
    locker_name { "Paczkomat #{locker_code}" }
    locker_address { Faker::Address.street_address }
    locker_city { Faker::Address.city }
    locker_post_code { "#{Faker::Number.number(digits: 2)}-#{Faker::Number.number(digits: 3)}" }
    price_per_unit { edition&.default_price || 5.0 }
    total_amount { quantity * price_per_unit }

    trait :confirmed do
      status { :confirmed }
      confirmed_at { Time.current }
    end

    trait :shipped do
      status { :shipped }
      confirmed_at { 1.day.ago }
    end

    trait :delivered do
      status { :delivered }
      confirmed_at { 3.days.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
