FactoryBot.define do
  factory :return do
    association :user, factory: :user, role: :leader
    association :edition

    quantity { 10 }
    status { :pending }
    locker_code { "KRA#{Faker::Number.number(digits: 3)}" }
    locker_name { "Paczkomat #{locker_code}" }
    notes { nil }

    trait :received do
      status { :received }
      received_at { Time.current }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
