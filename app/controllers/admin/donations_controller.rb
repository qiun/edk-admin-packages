module Admin
  class DonationsController < Admin::BaseController
    before_action :require_admin! # Only admins, warehouse has their own namespace

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
      @donation = Donation.find(params[:id])
    end

    def mark_as_paid
      @donation = Donation.find(params[:id])

      if @donation.payment_paid?
        redirect_to admin_donation_path(@donation), alert: "Darowizna jest już oznaczona jako opłacona"
        return
      end

      ActiveRecord::Base.transaction do
        @donation.update!(payment_status: :paid)

        # Send confirmation email
        begin
          DonationMailer.confirmation(@donation).deliver_later
        rescue => e
          Rails.logger.error "Failed to send confirmation email: #{e.message}"
        end

        # Create shipment if gift was requested and doesn't exist yet
        if @donation.want_gift? && @donation.locker_code.present? && @donation.shipment.nil?
          begin
            shipment = Shipment.create!(
              donation: @donation,
              status: "pending"
            )

            Apaczka::CreateShipmentJob.perform_later(shipment)
            Rails.logger.info "Created shipment ##{shipment.id} for donation ##{@donation.id}"
          rescue => e
            Rails.logger.error "Failed to create shipment: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
      end

      redirect_to admin_donation_path(@donation), notice: "Darowizna została oznaczona jako opłacona"
    end
  end
end
