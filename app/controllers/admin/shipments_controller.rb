module Admin
  class ShipmentsController < Admin::BaseController
    include RetryShipmentHandler

    before_action :require_admin! # Only admins, warehouse has their own namespace
    before_action :set_shipment, only: [ :show, :refresh_status, :download_waybill, :download_label, :retry_shipment ]

    def index
      @shipments = Shipment.includes(:order, :donation)
                           .order(created_at: :desc)

      # Default to pending shipments unless explicitly set
      status_filter = params[:status].presence || "pending"
      @shipments = @shipments.where(status: status_filter) unless status_filter == "all"

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
      if @shipment.status == "pending"
        redirect_to admin_shipment_path(@shipment), alert: "Wysyłka jest już w trakcie przetwarzania"
        return
      end

      cancellation = ensure_old_shipment_cancelled(@shipment)
      unless cancellation[:success]
        redirect_to admin_shipment_path(@shipment), alert: cancellation[:error]
        return
      end

      reset_and_retry_shipment(@shipment)
      redirect_to admin_shipment_path(@shipment), notice: "Wysyłka została ponowiona"
    end

    def download_label
      unless @shipment.label_pdf.present?
        redirect_to admin_shipment_path(@shipment), alert: "Brak etykiety PDF"
        return
      end

      send_data @shipment.label_pdf,
                filename: "etykieta_#{@shipment.id}.pdf",
                type: "application/pdf",
                disposition: "inline"
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
      case apaczka_status.to_s.downcase
      when "new", "pending"
        "pending"
      when "delivered", "ready_to_pickup"
        "delivered"
      when "cancelled", "failed", "returned"
        "failed"
      else
        "shipped"
      end
    end
  end
end
