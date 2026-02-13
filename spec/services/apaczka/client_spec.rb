require 'rails_helper'

RSpec.describe Apaczka::Client do
  let(:client) { described_class.new }
  let(:order) do
    create(:order, :confirmed,
      quantity: 10,
      locker_code: 'KRA010',
      locker_address: 'ul. Testowa 1',
      locker_city: 'Kraków',
      locker_post_code: '30-001'
    )
  end

  before do
    # Mock credentials
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :app_id).and_return('test_app_id')
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :app_secret).and_return('test_secret')
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :sandbox).and_return(false)
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :order_sender).and_return(nil)
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :donation_sender).and_return(nil)
  end

  describe '#generate_signature' do
    it 'generates correct HMAC signature' do
      endpoint = '/order_send/'
      data = '{"test":"data"}'
      expires = 1234567890

      signature = client.send(:generate_signature, endpoint, data, expires)

      # Verify it's a valid hex string
      expect(signature).to match(/^[a-f0-9]{64}$/)
    end

    it 'generates consistent signatures for same input' do
      endpoint = '/order_send/'
      data = '{"test":"data"}'
      expires = 1234567890

      sig1 = client.send(:generate_signature, endpoint, data, expires)
      sig2 = client.send(:generate_signature, endpoint, data, expires)

      expect(sig1).to eq(sig2)
    end

    it 'generates different signatures for different data' do
      endpoint = '/order_send/'
      expires = 1234567890

      sig1 = client.send(:generate_signature, endpoint, '{"test":"data1"}', expires)
      sig2 = client.send(:generate_signature, endpoint, '{"test":"data2"}', expires)

      expect(sig1).not_to eq(sig2)
    end
  end

  describe '#build_order_data' do
    it 'builds correct order structure' do
      data = client.send(:build_order_data, order)

      expect(data).to include(:service_id, :address, :pickup, :shipment, :content)
      expect(data[:service_id]).to eq(41)
    end

    it 'includes receiver information from order' do
      data = client.send(:build_order_data, order)

      receiver = data[:address][:receiver]
      expect(receiver[:name]).to eq(order.user.full_name)
      expect(receiver[:foreign_address_id]).to eq('KRA010')
    end

    it 'uses Magazyn EDK sender for orders' do
      data = client.send(:build_order_data, order)

      sender = data[:address][:sender]
      expect(sender[:name]).to eq("Magazyn EDK - Rafał Wojtkiewicz")
      expect(sender[:line1]).to eq("ul. Konarskiego 8")
      expect(sender[:city]).to eq("Świebodzin")
      expect(sender[:postal_code]).to eq("66-200")
    end

    it 'uses Sklep EDK sender for donations' do
      donation = create(:donation, :paid, :with_gift,
        locker_code: 'KRA010',
        locker_address: 'ul. Testowa 1',
        locker_city: 'Kraków',
        locker_post_code: '30-001'
      )
      data = client.send(:build_order_data, donation)

      sender = data[:address][:sender]
      expect(sender[:name]).to eq("Sklep EDK - Rafał Wojtkiewicz")
      expect(sender[:line1]).to eq("ul. Sobieskiego 19")
      expect(sender[:city]).to eq("Świebodzin")
      expect(sender[:postal_code]).to eq("66-200")
    end

    it 'calculates weight based on quantity for orders' do
      data = client.send(:build_order_data, order)

      shipment = data[:shipment].first
      # 10 pakietów * 0.3kg + 2.0kg = 5.0kg
      expect(shipment[:weight]).to eq(5.0)
    end
  end

  describe '#calculate_weight' do
    it 'calculates weight for order (small quantity)' do
      weight = client.send(:calculate_weight, 10, order)
      expect(weight).to eq(5.0) # 10 * 0.3 + 2.0
    end

    it 'caps weight at 24.9 for large orders' do
      weight = client.send(:calculate_weight, 100, order)
      expect(weight).to eq(24.9) # (100 * 0.3 + 2.0 = 32.0) capped at 24.9
    end
  end

  describe '#create_shipment' do
    context 'when API returns success' do
      let(:api_response) do
        {
          'status' => 200,
          'response' => {
            'order' => {
              'id' => 'AP123456',
              'waybill_number' => 'WB789',
              'tracking_url' => 'https://apaczka.pl/track/WB789'
            }
          }
        }
      end

      before do
        stub_request(:post, "https://www.apaczka.pl/api/v2/order_send/")
          .to_return(body: api_response.to_json, status: 200)
      end

      it 'returns success result' do
        result = client.create_shipment(order)

        expect(result[:success]).to be true
        expect(result[:order_id]).to eq('AP123456')
        expect(result[:waybill_number]).to eq('WB789')
        expect(result[:tracking_url]).to eq('https://apaczka.pl/track/WB789')
      end
    end

    context 'when API returns error' do
      let(:api_response) do
        {
          'status' => 400,
          'message' => 'Invalid data'
        }
      end

      before do
        stub_request(:post, "https://www.apaczka.pl/api/v2/order_send/")
          .to_return(body: api_response.to_json, status: 200)
      end

      it 'returns failure result' do
        result = client.create_shipment(order)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid data')
      end
    end
  end
end
