module Admin
  class DonationsController < Admin::BaseController
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
              order_type: "Donation",
              order_id: @donation.id,
              recipient_name: "#{@donation.first_name} #{@donation.last_name}",
              recipient_email: @donation.email,
              recipient_phone: @donation.phone,
              locker_code: @donation.locker_code,
              locker_name: @donation.locker_name,
              locker_address: @donation.locker_address,
              locker_city: @donation.locker_city,
              locker_post_code: @donation.locker_post_code,
              quantity: @donation.quantity,
              status: "pending"
            )

            Apaczka::CreateShipmentJob.perform_later(shipment)
          rescue => e
            Rails.logger.error "Failed to create shipment: #{e.message}"
          end
        end
      end

      redirect_to admin_donation_path(@donation), notice: "Darowizna została oznaczona jako opłacona"
    end
  end
end
