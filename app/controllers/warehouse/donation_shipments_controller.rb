# frozen_string_literal: true

module Warehouse
  class DonationShipmentsController < Warehouse::BaseController
    before_action :set_shipment, only: [:show, :mark_shipped, :unmark_shipped, :download_waybill]

    def index
      @shipments = Shipment.includes(:donation)
                          .where.not(donation_id: nil)
                          .order(created_at: :desc)

      # Filter by payment status - default to paid, unless "all" is selected
      payment_status = params[:payment_status].presence || "paid"
      unless payment_status == "all"
        @shipments = @shipments.joins(:donation)
                              .where(donations: { payment_status: payment_status })
      else
        @shipments = @shipments.joins(:donation)
      end

      # Filter by shipment status if provided
      if params[:shipment_status].present?
        @shipments = @shipments.where(status: params[:shipment_status])
      end
    end

    def show
      # Redirect to existing shipment detail view
      redirect_to warehouse_shipment_path(@shipment)
    end

    def mark_shipped
      if @shipment.update(status: "shipped", shipped_at: Time.current)
        # Send email to donor
        begin
          DonationMailer.shipment_sent(
            @shipment.donation,
            @shipment.waybill_number
          ).deliver_later
        rescue => e
          Rails.logger.error "Failed to send shipment email: #{e.message}"
        end

        respond_to do |format|
          format.html { redirect_to warehouse_donation_shipments_path, notice: "Wysyłka oznaczona jako wysłana" }
          format.turbo_stream
        end
      else
        redirect_to warehouse_donation_shipments_path, alert: "Nie udało się oznaczyć wysyłki"
      end
    end

    def unmark_shipped
      if @shipment.update(status: "label_printed", shipped_at: nil)
        respond_to do |format|
          format.html { redirect_to warehouse_donation_shipments_path, notice: "Status wysyłki został cofnięty. UWAGA: Email został już wysłany do darczyńcy." }
          format.turbo_stream
        end
      else
        redirect_to warehouse_donation_shipments_path, alert: "Nie udało się cofnąć statusu wysyłki"
      end
    end

    def download_waybill
      unless @shipment.apaczka_order_id.present?
        redirect_to warehouse_donation_shipments_path, alert: "Brak ID zamówienia w aPaczka"
        return
      end

      client = Apaczka::Client.new
      pdf_data = client.get_waybill(@shipment.apaczka_order_id)

      if pdf_data.present?
        send_data pdf_data,
                  filename: "list_przewozowy_#{@shipment.id}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      else
        redirect_to warehouse_donation_shipments_path, alert: "Nie udało się pobrać listu przewozowego"
      end
    end

    private

    def set_shipment
      @shipment = Shipment.includes(:donation).find(params[:id])
    end
  end
end
