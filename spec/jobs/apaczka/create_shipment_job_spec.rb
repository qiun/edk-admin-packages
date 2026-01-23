require 'rails_helper'

RSpec.describe Apaczka::CreateShipmentJob, type: :job do
  let(:order) { create(:order, status: :confirmed, quantity: 10) }
  let(:client) { instance_double(Apaczka::Client) }

  before do
    allow(Apaczka::Client).to receive(:new).and_return(client)
  end

  describe '#perform' do
    context 'when shipment creation succeeds' do
      let(:api_result) do
        {
          success: true,
          order_id: 'AP123456',
          waybill_number: 'WB789',
          tracking_url: 'https://apaczka.pl/track/WB789'
        }
      end

      before do
        allow(client).to receive(:create_shipment).with(order).and_return(api_result)
        allow(client).to receive(:get_waybill).with('AP123456').and_return('PDF_BINARY_DATA')
      end

      it 'creates shipment record' do
        expect {
          described_class.perform_now(order.id)
        }.to change(Shipment, :count).by(1)

        shipment = order.reload.shipment
        expect(shipment.apaczka_order_id).to eq('AP123456')
        expect(shipment.waybill_number).to eq('WB789')
        expect(shipment.tracking_url).to eq('https://apaczka.pl/track/WB789')
        expect(shipment.status).to eq('label_printed')
      end

      it 'stores PDF label' do
        described_class.perform_now(order.id)

        shipment = order.reload.shipment
        expect(shipment.label_pdf).to eq('PDF_BINARY_DATA')
      end

      it 'updates inventory' do
        inventory = order.edition.inventory
        expect(inventory).to receive(:ship).with(order.quantity, reference: order.id)

        described_class.perform_now(order.id)
      end

      it 'updates order status to shipped' do
        described_class.perform_now(order.id)

        expect(order.reload.status).to eq('shipped')
      end
    end

    context 'when shipment creation fails' do
      let(:api_result) do
        {
          success: false,
          error: 'Invalid address'
        }
      end

      before do
        allow(client).to receive(:create_shipment).with(order).and_return(api_result)
      end

      it 'raises StandardError' do
        expect {
          described_class.perform_now(order.id)
        }.to raise_error(StandardError, /aPaczka API error/)
      end

      it 'does not create shipment record' do
        expect {
          begin
            described_class.perform_now(order.id)
          rescue StandardError
            # Expected error
          end
        }.not_to change(Shipment, :count)
      end

      it 'logs error' do
        allow(Rails.logger).to receive(:error)

        begin
          described_class.perform_now(order.id)
        rescue StandardError
          # Expected
        end

        expect(Rails.logger).to have_received(:error).with(/aPaczka shipment creation failed/)
      end
    end

    context 'when order is not confirmed' do
      let(:pending_order) { create(:order, status: :pending) }

      it 'does not create shipment' do
        expect(client).not_to receive(:create_shipment)

        expect {
          described_class.perform_now(pending_order.id)
        }.not_to change(Shipment, :count)
      end
    end
  end
end
