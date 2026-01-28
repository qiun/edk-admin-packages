require 'rails_helper'

RSpec.describe Apaczka::SyncStatusJob, type: :job do
  let(:client) { instance_double(Apaczka::Client) }
  let(:edition) { create(:edition) }

  before do
    allow(Apaczka::Client).to receive(:new).and_return(client)
    allow(ShipmentMailer).to receive(:delivered).and_return(double(deliver_later: true))
    # Default stub for get_order_status - can be overridden in specific tests
    allow(client).to receive(:get_order_status).and_return('SHIPPED')
  end

  describe '#perform' do
    let!(:shipped_order) { create(:order, edition: edition, status: :confirmed) }
    let!(:in_transit_order) { create(:order, edition: edition, status: :confirmed) }
    let!(:delivered_order) { create(:order, edition: edition, status: :confirmed) }

    let!(:shipped_shipment) do
      create(:shipment, :shipped, order: shipped_order)
    end

    let!(:in_transit_shipment) do
      create(:shipment, :in_transit, order: in_transit_order)
    end

    let!(:delivered_shipment) do
      create(:shipment, :delivered, order: delivered_order)
    end

    it 'only syncs non-delivered shipments' do
      expect(client).to receive(:get_order_status).with(shipped_shipment.apaczka_order_id).and_return('SHIPPED')
      expect(client).to receive(:get_order_status).with(in_transit_shipment.apaczka_order_id).and_return('IN_TRANSIT')
      expect(client).not_to receive(:get_order_status).with(delivered_shipment.apaczka_order_id)

      described_class.perform_now
    end

    context 'when status changes to in_transit' do
      before do
        allow(client).to receive(:get_order_status).with(shipped_shipment.apaczka_order_id).and_return('IN_TRANSIT')
      end

      it 'updates shipment status' do
        described_class.perform_now

        expect(shipped_shipment.reload.status).to eq('in_transit')
      end
    end

    context 'when status changes to delivered' do
      before do
        allow(client).to receive(:get_order_status).with(in_transit_shipment.apaczka_order_id).and_return('DELIVERED')
      end

      it 'updates shipment status to delivered' do
        described_class.perform_now

        expect(in_transit_shipment.reload.status).to eq('delivered')
      end

      it 'sets delivered_at timestamp' do
        described_class.perform_now

        expect(in_transit_shipment.reload.delivered_at).to be_present
      end

      it 'updates order status to delivered' do
        described_class.perform_now

        expect(in_transit_shipment.source.reload.status).to eq('delivered')
      end

      it 'sends delivery notification email' do
        expect(ShipmentMailer).to receive(:delivered).with(in_transit_shipment)

        described_class.perform_now
      end
    end

    context 'when API returns error for a shipment' do
      before do
        allow(client).to receive(:get_order_status).with(shipped_shipment.apaczka_order_id).and_raise(StandardError, 'API Error')
        allow(client).to receive(:get_order_status).with(in_transit_shipment.apaczka_order_id).and_return('IN_TRANSIT')
      end

      it 'continues processing other shipments' do
        allow(Rails.logger).to receive(:error)

        described_class.perform_now

        # Second shipment should still be processed
        expect(in_transit_shipment.reload.status).to eq('in_transit')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        described_class.perform_now

        expect(Rails.logger).to have_received(:error).with(/Failed to sync status/)
      end
    end

    describe 'status mapping' do
      {
        'READY_TO_SHIP' => 'label_printed',
        'PICKED_UP' => 'in_transit',
        'IN_TRANSIT' => 'in_transit',
        'DELIVERED' => 'delivered',
        'READY_TO_PICKUP' => 'delivered',
        'RETURNED' => 'failed',
        'UNKNOWN_STATUS' => 'shipped'
      }.each do |apaczka_status, expected_status|
        it "maps #{apaczka_status} to #{expected_status}" do
          allow(client).to receive(:get_order_status).with(shipped_shipment.apaczka_order_id).and_return(apaczka_status)

          described_class.perform_now

          expect(shipped_shipment.reload.status).to eq(expected_status)
        end
      end
    end
  end
end
