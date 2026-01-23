require 'rails_helper'

RSpec.describe Admin::SettlementsController, type: :controller do
  let(:admin) { create(:user, role: :admin) }
  let(:edition) { create(:edition) }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    let!(:settlement1) { create(:settlement, :calculated, edition: edition) }
    let!(:settlement2) { create(:settlement, :paid, edition: edition) }

    it 'returns success response' do
      get :index, params: { edition_id: edition.id }
      expect(response).to be_successful
    end

    it 'assigns settlements for edition' do
      get :index, params: { edition_id: edition.id }
      expect(assigns(:settlements)).to match_array([settlement1, settlement2])
    end

    it 'calculates summary statistics' do
      get :index, params: { edition_id: edition.id }
      summary = assigns(:summary)

      expect(summary[:total_due]).to eq(800.0) # 400 + 400
      expect(summary[:total_paid]).to eq(400.0)
      expect(summary[:pending_count]).to eq(0)
    end

    context 'without edition_id' do
      it 'uses current edition' do
        allow(controller).to receive(:current_edition).and_return(edition)
        get :index

        expect(assigns(:edition)).to eq(edition)
      end
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user, role: :leader) }
    let!(:settlement) { create(:settlement, user: user, edition: edition) }
    let!(:order) { create(:order, user: user, edition: edition) }
    let!(:return_record) { create(:return, user: user, edition: edition) }
    let!(:sales_report) { create(:sales_report, user: user, edition: edition) }

    it 'returns success response' do
      get :show, params: { id: settlement.id }
      expect(response).to be_successful
    end

    it 'assigns settlement' do
      get :show, params: { id: settlement.id }
      expect(assigns(:settlement)).to eq(settlement)
    end

    it 'assigns related records' do
      get :show, params: { id: settlement.id }

      expect(assigns(:orders)).to include(order)
      expect(assigns(:returns)).to include(return_record)
      expect(assigns(:reports)).to include(sales_report)
    end
  end

  describe 'POST #mark_paid' do
    let(:settlement) { create(:settlement, :calculated, edition: edition) }

    it 'updates settlement with payment' do
      post :mark_paid, params: { id: settlement.id, amount: 400.0 }

      settlement.reload
      expect(settlement.amount_paid).to eq(400.0)
      expect(settlement.status).to eq('paid')
      expect(settlement.settled_at).to be_present
    end

    it 'redirects to settlement show page' do
      post :mark_paid, params: { id: settlement.id, amount: 400.0 }

      expect(response).to redirect_to(admin_settlement_path(settlement))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST #recalculate' do
    let(:user) { create(:user, role: :leader) }
    let(:settlement) { create(:settlement, user: user, edition: edition) }

    before do
      create(:order, :shipped, user: user, edition: edition, quantity: 100)
      create(:sales_report, user: user, edition: edition, quantity_sold: 80)
    end

    it 'recalculates settlement' do
      post :recalculate, params: { id: settlement.id }

      settlement.reload
      expect(settlement.total_sent).to eq(100)
      expect(settlement.total_sold).to eq(80)
      expect(settlement.amount_due).to eq(400.0)
    end

    it 'redirects to settlement show page' do
      post :recalculate, params: { id: settlement.id }

      expect(response).to redirect_to(admin_settlement_path(settlement))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET #export' do
    let!(:settlement1) { create(:settlement, :calculated, edition: edition) }
    let!(:settlement2) { create(:settlement, :paid, edition: edition) }

    context 'CSV format' do
      it 'returns CSV file' do
        get :export, params: { edition_id: edition.id }, format: :csv

        expect(response).to be_successful
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include("rozliczenia-#{edition.year}.csv")
      end

      it 'includes settlement data' do
        get :export, params: { edition_id: edition.id }, format: :csv

        csv_content = response.body
        expect(csv_content).to include('Lider')
        expect(csv_content).to include('Email')
        expect(csv_content).to include(settlement1.user.full_name)
      end
    end
  end
end
