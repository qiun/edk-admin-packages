FactoryBot.define do
  factory :sales_report do
    association :user, factory: :user, role: :leader
    association :edition

    quantity_sold { 50 }
    reported_at { Time.current }
    notes { nil }

    trait :with_notes do
      notes { Faker::Lorem.sentence }
    end
  end
end
