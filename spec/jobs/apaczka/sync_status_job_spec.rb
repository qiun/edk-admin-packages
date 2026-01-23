require 'rails_helper'

RSpec.describe Apaczka::SyncStatusJob, type: :job do
  let(:client) { instance_double(Apaczka::Client) }

  before do
    allow(Apaczka::Client).to receive(:new).and_return(client)
  end

  describe '#perform' do
    let!(:shipped_shipment) do
      create(:shipment,
        status: :shipped,
        apaczka_order_id: 'AP001'
      )
    end

    let!(:in_transit_shipment) do
      create(:shipment,
        status: :in_transit,
        apaczka_order_id: 'AP002'
      )
    end

    let!(:delivered_shipment) do
      create(:shipment,
        status: :delivered,
        apaczka_order_id: 'AP003'
      )
    end

    it 'only syncs non-delivered shipments' do
      expect(client).to receive(:get_order_status).with('AP001').and_return('SHIPPED')
      expect(client).to receive(:get_order_status).with('AP002').and_return('IN_TRANSIT')
      expect(client).not_to receive(:get_order_status).with('AP003')

      described_class.perform_now
    end

    context 'when status changes to in_transit' do
      before do
        allow(client).to receive(:get_order_status).with('AP001').and_return('IN_TRANSIT')
      end

      it 'updates shipment status' do
        described_class.perform_now

        expect(shipped_shipment.reload.status).to eq('in_transit')
      end
    end

    context 'when status changes to delivered' do
      before do
        allow(client).to receive(:get_order_status).with('AP002').and_return('DELIVERED')
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

        expect(in_transit_shipment.order.reload.status).to eq('delivered')
      end
    end

    context 'when API returns error for a shipment' do
      before do
        allow(client).to receive(:get_order_status).with('AP001').and_raise(StandardError, 'API Error')
        allow(client).to receive(:get_order_status).with('AP002').and_return('IN_TRANSIT')
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
          allow(client).to receive(:get_order_status).with('AP001').and_return(apaczka_status)

          described_class.perform_now

          expect(shipped_shipment.reload.status).to eq(expected_status)
        end
      end
    end
  end
end
