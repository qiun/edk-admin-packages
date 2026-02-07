module Admin
  class ShipmentsController < Admin::BaseController
    before_action :require_admin! # Only admins, warehouse has their own namespace
    before_action :set_shipment, only: [ :show, :refresh_status, :download_waybill, :retry_shipment ]

    def index
      @shipments = Shipment.includes(:order, :donation)
                           .order(created_at: :desc)

      @shipments = @shipments.where(status: params[:status]) if params[:status].present?

      # Filter by type (order or donation)
      case params[:type]
      when "order"
        @shipments = @shipments.for_orders
      when "donation"
        @shipments = @shipments.for_donations
      end
    end

    def show
    end

    def refresh_status
      unless @shipment.apaczka_order_id.present?
        redirect_to admin_shipment_path(@shipment), alert: "Brak ID zamówienia w aPaczka"
        return
      end

      client = Apaczka::Client.new
      status = client.get_order_status(@shipment.apaczka_order_id)

      if status.present?
        @shipment.update(status: map_apaczka_status(status))
        redirect_to admin_shipment_path(@shipment), notice: "Status został odświeżony: #{@shipment.status}"
      else
        redirect_to admin_shipment_path(@shipment), alert: "Nie udało się pobrać statusu z aPaczka"
      end
    end

    def retry_shipment
      unless @shipment.status == "failed"
        redirect_to admin_shipment_path(@shipment), alert: "Tylko nieudane wysyłki można ponowić"
        return
      end

      @shipment.update!(status: "pending", apaczka_response: nil)
      Apaczka::CreateShipmentJob.perform_later(@shipment)

      redirect_to admin_shipment_path(@shipment), notice: "Wysyłka została ponowiona"
    end

    def download_waybill
      unless @shipment.apaczka_order_id.present?
        redirect_to admin_shipment_path(@shipment), alert: "Brak ID zamówienia w aPaczka"
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
        redirect_to admin_shipment_path(@shipment), alert: "Nie udało się pobrać listu przewozowego z aPaczka"
      end
    end

    private

    def set_shipment
      @shipment = Shipment.find(params[:id])
    end

    def map_apaczka_status(apaczka_status)
      # Map aPaczka status to our internal status enum
      case apaczka_status.to_s.downcase
      when "new", "pending"
        "pending"
      when "confirmed", "label_created"
        "label_printed"
      when "sent", "dispatched"
        "shipped"
      when "in_transit", "out_for_delivery"
        "in_transit"
      when "delivered"
        "delivered"
      when "cancelled", "failed", "returned"
        "failed"
      else
        "pending" # Default fallback
      end
    end
  end
end
