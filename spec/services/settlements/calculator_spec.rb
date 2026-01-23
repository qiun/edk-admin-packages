require 'rails_helper'

RSpec.describe Settlements::Calculator do
  let(:user) { create(:user, role: :leader) }
  let(:edition) { create(:edition) }
  let(:calculator) { described_class.new(user, edition) }

  describe '#call' do
    context 'when no data exists' do
      it 'creates settlement with zero values' do
        result = calculator.call

        expect(result).to be_persisted
        expect(result.total_sent).to eq(0)
        expect(result.total_returned).to eq(0)
        expect(result.total_sold).to eq(0)
        expect(result.amount_due).to eq(0)
        expect(result.status).to eq('pending')
      end
    end

    context 'when orders exist' do
      let!(:shipped_order) do
        create(:order, :shipped, user: user, edition: edition, quantity: 100)
      end

      let!(:delivered_order) do
        create(:order, :delivered, user: user, edition: edition, quantity: 50)
      end

      let!(:pending_order) do
        create(:order, user: user, edition: edition, quantity: 25)
      end

      it 'counts only shipped and delivered orders' do
        result = calculator.call

        expect(result.total_sent).to eq(150) # 100 + 50, bez pending
      end
    end

    context 'when returns exist' do
      let!(:order) { create(:order, :shipped, user: user, edition: edition, quantity: 100) }
      let!(:return_record) do
        create(:return, user: user, edition: edition, quantity: 10, status: :received)
      end

      it 'counts received returns' do
        result = calculator.call

        expect(result.total_returned).to eq(10)
      end
    end

    context 'when sales reports exist' do
      let!(:order) { create(:order, :shipped, user: user, edition: edition, quantity: 100) }
      let!(:sales_report) do
        create(:sales_report, user: user, edition: edition, quantity_sold: 80)
      end

      it 'counts sold quantity' do
        result = calculator.call

        expect(result.total_sold).to eq(80)
      end

      it 'calculates amount due based on sold quantity' do
        result = calculator.call

        # 80 pakietów * 5 zł (default_price) = 400 zł
        expect(result.amount_due).to eq(400.0)
      end
    end

    context 'when custom price is set' do
      before do
        user.leader_settings.create!(edition: edition, custom_price: 4.0)
      end

      let!(:sales_report) do
        create(:sales_report, user: user, edition: edition, quantity_sold: 50)
      end

      it 'uses custom price for calculation' do
        result = calculator.call

        expect(result.price_per_unit).to eq(4.0)
        expect(result.amount_due).to eq(200.0) # 50 * 4.0
      end
    end

    context 'when settlement already exists' do
      let!(:existing_settlement) do
        create(:settlement,
          user: user,
          edition: edition,
          total_sent: 50,
          amount_paid: 100.0
        )
      end

      let!(:sales_report) do
        create(:sales_report, user: user, edition: edition, quantity_sold: 40)
      end

      it 'updates existing settlement' do
        result = calculator.call

        expect(result.id).to eq(existing_settlement.id)
        expect(result.total_sold).to eq(40)
        expect(result.amount_paid).to eq(100.0) # Preserved
      end
    end

    describe 'status determination' do
      let!(:sales_report) do
        create(:sales_report, user: user, edition: edition, quantity_sold: 50)
      end

      context 'when nothing paid' do
        it 'sets status to pending' do
          result = calculator.call

          expect(result.status).to eq('pending')
        end
      end

      context 'when partially paid' do
        before do
          settlement = user.settlements.find_or_initialize_by(edition: edition)
          settlement.update!(amount_paid: 100.0)
        end

        it 'sets status to calculated' do
          result = calculator.call

          # amount_due = 50 * 5 = 250, paid = 100
          expect(result.status).to eq('calculated')
        end
      end

      context 'when fully paid' do
        before do
          settlement = user.settlements.find_or_initialize_by(edition: edition)
          settlement.update!(amount_paid: 300.0)
        end

        it 'sets status to paid' do
          result = calculator.call

          # amount_due = 50 * 5 = 250, paid = 300
          expect(result.status).to eq('paid')
        end
      end
    end
  end
end
