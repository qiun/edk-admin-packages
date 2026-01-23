FactoryBot.define do
  factory :settlement do
    association :user, factory: :user, role: :leader
    association :edition

    total_sent { 0 }
    total_returned { 0 }
    total_sold { 0 }
    price_per_unit { 5.0 }
    amount_due { 0.0 }
    amount_paid { 0.0 }
    status { :pending }
    settled_at { nil }

    trait :calculated do
      total_sent { 100 }
      total_sold { 80 }
      amount_due { 400.0 }
      status { :calculated }
    end

    trait :paid do
      total_sent { 100 }
      total_sold { 80 }
      amount_due { 400.0 }
      amount_paid { 400.0 }
      status { :paid }
      settled_at { Time.current }
    end

    trait :overpaid do
      total_sent { 100 }
      total_sold { 80 }
      amount_due { 400.0 }
      amount_paid { 500.0 }
      status { :paid }
      settled_at { Time.current }
    end
  end
end
