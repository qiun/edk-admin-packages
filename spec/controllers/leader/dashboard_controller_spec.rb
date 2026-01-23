require 'rails_helper'

RSpec.describe Leader::DashboardController, type: :controller do
  let(:edition) { create(:edition) }
  let(:leader) { create(:user, role: :leader) }

  describe 'authentication and authorization' do
    context 'when not authenticated' do
      it 'redirects to login' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as non-leader' do
      let(:regular_user) { create(:user, role: :warehouse) }

      before { sign_in regular_user }

      it 'redirects to root with alert' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when authenticated as leader' do
      before { sign_in leader }

      it 'allows access' do
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #index' do
    before do
      sign_in leader
      allow(controller).to receive(:current_edition).and_return(edition)
    end

    context 'with no orders' do
      it 'returns success response' do
        get :index
        expect(response).to be_successful
      end

      it 'initializes stats with zeros' do
        get :index
        stats = assigns(:stats)

        expect(stats[:total_ordered]).to eq(0)
        expect(stats[:total_shipped]).to eq(0)
        expect(stats[:total_reported_sold]).to eq(0)
        expect(stats[:amount_due]).to eq(0)
      end

      it 'has empty recent orders' do
        get :index
        expect(assigns(:recent_orders)).to be_empty
      end
    end

    context 'with existing orders' do
      let!(:order1) { create(:order, user: leader, edition: edition, quantity: 100, status: :shipped) }
      let!(:order2) { create(:order, user: leader, edition: edition, quantity: 50, status: :pending) }
      let!(:sales_report) { create(:sales_report, user: leader, edition: edition, quantity_sold: 80) }

      it 'calculates correct stats' do
        get :index
        stats = assigns(:stats)

        expect(stats[:total_ordered]).to eq(150)
        expect(stats[:total_shipped]).to eq(100)
        expect(stats[:total_reported_sold]).to eq(80)
      end

      it 'assigns recent orders' do
        get :index
        recent = assigns(:recent_orders)

        expect(recent).to include(order1, order2)
        expect(recent.length).to be <= 5
      end
    end

    context 'ordering permission' do
      it 'checks if leader can order' do
        get :index
        expect(assigns(:can_order)).to be_in([true, false])
      end

      context 'when leader is locked' do
        before do
          leader.update(ordering_locked_for: [edition.id])
        end

        it 'sets can_order to false' do
          get :index
          expect(assigns(:can_order)).to eq(false)
        end
      end
    end
  end
end
