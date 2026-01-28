FactoryBot.define do
  factory :shipment do
    # Default to Order association
    association :order
    status { :pending }

    trait :with_apaczka_data do
      apaczka_order_id { "AP#{Faker::Alphanumeric.alphanumeric(number: 10).upcase}" }
      waybill_number { "WB#{Faker::Number.number(digits: 12)}" }
      tracking_url { "https://apaczka.pl/track/#{waybill_number}" }
    end

    trait :label_printed do
      status { :label_printed }
      with_apaczka_data
    end

    trait :shipped do
      status { :shipped }
      shipped_at { 1.day.ago }
      with_apaczka_data
    end

    trait :in_transit do
      status { :in_transit }
      shipped_at { 2.days.ago }
      with_apaczka_data
    end

    trait :delivered do
      status { :delivered }
      shipped_at { 5.days.ago }
      delivered_at { 1.day.ago }
      with_apaczka_data
    end

    trait :failed do
      status { :failed }
    end

    trait :with_label do
      label_pdf { "PDF_BINARY_DATA" }
    end

    trait :with_donation do
      order { nil }
      association :donation
    end
  end
end
