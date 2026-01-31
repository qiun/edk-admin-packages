module Warehouse
  class DonationsController < Warehouse::BaseController
    def index
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @donations = Donation.for_edition(@edition)
                          .includes(:shipment)
                          .order(created_at: :desc)

      @donations = @donations.where(payment_status: params[:status]) if params[:status].present?

      @summary = {
        total_amount: @donations.paid.sum(:amount),
        total_quantity: @donations.paid.sum(:quantity),
        donation_count: @donations.paid.count
      }
    end

    def show
      @donation = Donation.includes(:shipment, :edition).find(params[:id])
    end
  end
end
