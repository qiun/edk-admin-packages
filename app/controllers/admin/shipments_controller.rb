module Admin
  class ShipmentsController < Admin::BaseController
    before_action :set_shipment, only: [ :show, :refresh_status, :download_waybill ]

    def index
      @shipments = Shipment.includes(:order, :donation)
                           .order(created_at: :desc)

      @shipments = @shipments.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def refresh_status
      # TODO: Implement in Phase 4 with aPaczka integration
      # Apaczka::SyncStatusJob.perform_now(@shipment)
      redirect_to admin_shipment_path(@shipment), notice: "Status został odświeżony"
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
  end
end
