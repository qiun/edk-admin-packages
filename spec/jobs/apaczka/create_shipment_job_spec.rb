require 'rails_helper'

RSpec.describe Apaczka::CreateShipmentJob, type: :job do
  let(:order) { create(:order, status: :confirmed, quantity: 10) }
  let(:shipment) { create(:shipment, order: order) }
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
        allow(client).to receive(:create_shipment).with(an_instance_of(Order)).and_return(api_result)
        allow(client).to receive(:get_waybill).with('AP123456').and_return('PDF_BINARY_DATA')
        allow(ShipmentMailer).to receive(:shipped).and_return(double(deliver_later: true))
      end

      it 'updates shipment record with aPaczka data' do
        described_class.perform_now(shipment.id)

        shipment.reload
        expect(shipment.apaczka_order_id).to eq('AP123456')
        expect(shipment.waybill_number).to eq('WB789')
        expect(shipment.tracking_url).to eq('https://apaczka.pl/track/WB789')
        expect(shipment.status).to eq('label_printed')
      end

      it 'stores PDF label' do
        described_class.perform_now(shipment.id)

        shipment.reload
        expect(shipment.label_pdf).to eq('PDF_BINARY_DATA')
      end

      it 'updates inventory' do
        inventory = order.edition.inventory
        initial_shipped = inventory.shipped

        described_class.perform_now(shipment.id)

        inventory.reload
        expect(inventory.shipped).to eq(initial_shipped + order.quantity)
      end

      it 'updates order status to shipped' do
        described_class.perform_now(shipment.id)

        expect(order.reload.status).to eq('shipped')
      end

      it 'sends shipment notification email' do
        expect(ShipmentMailer).to receive(:shipped).with(shipment)

        described_class.perform_now(shipment.id)
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
        allow(client).to receive(:create_shipment).with(an_instance_of(Order)).and_return(api_result)
      end

      it 'raises StandardError' do
        expect {
          described_class.perform_now(shipment.id)
        }.to raise_error(StandardError, /aPaczka API error/)
      end

      it 'updates shipment status to failed' do
        begin
          described_class.perform_now(shipment.id)
        rescue StandardError
          # Expected error
        end

        shipment.reload
        expect(shipment.status).to eq('failed')
        expect(shipment.apaczka_response['error']).to eq('Invalid address')
      end

      it 'logs error' do
        allow(Rails.logger).to receive(:error)

        begin
          described_class.perform_now(shipment.id)
        rescue StandardError
          # Expected
        end

        expect(Rails.logger).to have_received(:error).with(/aPaczka shipment creation failed/)
      end
    end

    context 'when order is not confirmed' do
      let(:pending_order) { create(:order, status: :pending) }
      let(:pending_shipment) { create(:shipment, order: pending_order) }

      it 'does not create shipment in aPaczka' do
        expect(client).not_to receive(:create_shipment)

        described_class.perform_now(pending_shipment.id)
      end
    end
  end
end
