require 'rails_helper'

RSpec.describe Apaczka::Client do
  let(:client) { described_class.new }
  let(:order) do
    create(:order,
      quantity: 10,
      locker_code: 'KRA010',
      locker_address: 'ul. Testowa 1',
      locker_city: 'Kraków',
      locker_post_code: '30-001',
      status: :confirmed
    )
  end

  before do
    # Mock credentials
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :app_id).and_return('test_app_id')
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :app_secret).and_return('test_secret')
    allow(Rails.application.credentials).to receive(:dig).with(:apaczka, :sender).and_return(nil)
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

      expect(data).to include(:order)
      expect(data[:order]).to include(:service_id, :pickup, :receiver, :parcels, :comment)
      expect(data[:order][:service_id]).to eq('INPOST_COURIER_POINT')
    end

    it 'includes receiver information from order' do
      data = client.send(:build_order_data, order)

      receiver = data[:order][:receiver]
      expect(receiver[:name]).to eq(order.user.full_name)
      expect(receiver[:foreign_address_id]).to eq('KRA010')
      expect(receiver[:is_pickup_point]).to be true
    end

    it 'calculates weight based on quantity' do
      data = client.send(:build_order_data, order)

      parcel = data[:order][:parcels].first
      # 10 pakietów * 0.15kg + 0.5kg karton = 2.0kg
      expect(parcel[:weight]).to eq(2.0)
    end
  end

  describe '#calculate_weight' do
    it 'calculates weight for small quantity' do
      weight = client.send(:calculate_weight, 10)
      expect(weight).to eq(2.0) # 10 * 0.15 + 0.5
    end

    it 'calculates weight for large quantity' do
      weight = client.send(:calculate_weight, 100)
      expect(weight).to eq(15.5) # 100 * 0.15 + 0.5
    end
  end

  describe '#create_shipment' do
    context 'when API returns success' do
      let(:api_response) do
        {
          'status' => 200,
          'response' => {
            'id' => 'AP123456',
            'waybill_number' => 'WB789',
            'tracking_url' => 'https://apaczka.pl/track/WB789'
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
          .to_return(body: api_response.to_json, status: 400)
      end

      it 'returns failure result' do
        result = client.create_shipment(order)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Invalid data')
      end
    end
  end
end
