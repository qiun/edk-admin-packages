FactoryBot.define do
  factory :shipment do
    association :order

    apaczka_order_id { "AP#{Faker::Alphanumeric.alphanumeric(number: 10).upcase}" }
    waybill_number { "WB#{Faker::Number.number(digits: 12)}" }
    tracking_url { "https://apaczka.pl/track/#{waybill_number}" }
    status { :pending }

    trait :label_printed do
      status { :label_printed }
    end

    trait :shipped do
      status { :shipped }
      shipped_at { 1.day.ago }
    end

    trait :in_transit do
      status { :in_transit }
      shipped_at { 2.days.ago }
    end

    trait :delivered do
      status { :delivered }
      shipped_at { 5.days.ago }
      delivered_at { 1.day.ago }
    end

    trait :failed do
      status { :failed }
    end

    trait :with_label do
      label_pdf { "PDF_BINARY_DATA" }
    end
  end
end
