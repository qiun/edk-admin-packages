module Admin
  class DonationsController < Admin::BaseController
    include RetryShipmentHandler

    before_action :require_admin! # Only admins, warehouse has their own namespace

    def index
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @donations = Donation.for_edition(@edition)
                           .includes(:shipment)
                           .order(created_at: :desc)

      # Default to pending donations unless explicitly set
      status_filter = params[:status].presence || "pending"
      @donations = @donations.where(payment_status: status_filter) unless status_filter == "all"

      @summary = {
        total_amount: @donations.paid.sum(:amount),
        total_quantity: @donations.paid.sum(:quantity),
        donation_count: @donations.paid.count
      }
    end

    def show
      @donation = Donation.find(params[:id])
    end

    def retry_shipment
      @donation = Donation.find(params[:id])
      shipment = @donation.shipment

      if shipment.nil?
        redirect_to admin_donation_path(@donation), alert: "Brak wysyłki do ponowienia"
        return
      end

      if shipment.status == "pending"
        redirect_to admin_donation_path(@donation), alert: "Wysyłka jest już w trakcie przetwarzania"
        return
      end

      cancellation = ensure_old_shipment_cancelled(shipment)
      unless cancellation[:success]
        redirect_to admin_donation_path(@donation), alert: cancellation[:error]
        return
      end

      reset_and_retry_shipment(shipment)
      redirect_to admin_donation_path(@donation), notice: "Wysyłka została ponowiona"
    end

    def mark_shipped
      @donation = Donation.find(params[:id])
      shipment = @donation.shipment

      if shipment.nil?
        redirect_to admin_donation_path(@donation), alert: "Brak wysyłki"
        return
      end

      if shipment.update(status: "shipped", shipped_at: Time.current)
        begin
          DonationMailer.shipment_sent(@donation, shipment.waybill_number).deliver_later
        rescue => e
          Rails.logger.error "Failed to send shipment email: #{e.message}"
        end

        redirect_to admin_donation_path(@donation), notice: "Wysyłka oznaczona jako wysłana"
      else
        redirect_to admin_donation_path(@donation), alert: "Nie udało się oznaczyć wysyłki"
      end
    end

    def cancel
      @donation = Donation.find(params[:id])

      # Cancel aPaczka shipment if exists
      if @donation.shipment.present? && @donation.shipment.apaczka_order_id.present?
        cancellation = ensure_old_shipment_cancelled(@donation.shipment)
        unless cancellation[:success]
          redirect_to admin_donation_path(@donation), alert: "Nie udało się anulować wysyłki w aPaczka: #{cancellation[:error]}"
          return
        end
        @donation.shipment.update!(status: "failed")
      elsif @donation.shipment.present?
        @donation.shipment.update!(status: "failed")
      end

      @donation.update!(payment_status: :refunded)
      redirect_to admin_donation_path(@donation), notice: "Cegiełka została anulowana"
    end

  end
end
