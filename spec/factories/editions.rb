FactoryBot.define do
  factory :edition do
    name { "EDK #{year}" }
    year { 2026 }
    default_price { 5.0 }
    donor_price { 3.0 }
    status { :active }
    is_active { true }
    ordering_locked { false }

    after(:create) do |edition|
      # Inventory is created automatically via callback
    end

    trait :draft do
      status { :draft }
      is_active { false }
    end

    trait :closed do
      status { :closed }
      is_active { false }
    end

    trait :with_locked_ordering do
      ordering_locked { true }
    end
  end
end
