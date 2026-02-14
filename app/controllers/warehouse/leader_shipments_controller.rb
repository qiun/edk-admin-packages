# frozen_string_literal: true

module Warehouse
  class LeaderShipmentsController < Warehouse::BaseController
    before_action :set_shipment, only: [:show, :mark_shipped, :unmark_shipped, :download_waybill]

    def index
      @shipments = Shipment.includes(order: [:user, :area_group])
                          .where.not(order_id: nil)
                          .order(created_at: :desc)

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
      if @shipment.update(status: "picked_up", shipped_at: Time.current)
        # Send email to leader
        begin
          OrderMailer.shipment_sent(
            @shipment.order,
            @shipment.waybill_number
          ).deliver_later
        rescue => e
          Rails.logger.error "Failed to send shipment email to leader: #{e.message}"
        end

        respond_to do |format|
          format.html { redirect_to warehouse_leader_shipments_path, notice: "Wysyłka oznaczona jako wysłana" }
          format.turbo_stream
        end
      else
        redirect_to warehouse_leader_shipments_path, alert: "Nie udało się oznaczyć wysyłki"
      end
    end

    def unmark_shipped
      if @shipment.update(shipped_at: nil)
        respond_to do |format|
          format.html { redirect_to warehouse_leader_shipments_path, notice: "Status wysyłki został cofnięty. UWAGA: Email został już wysłany do lidera." }
          format.turbo_stream
        end
      else
        redirect_to warehouse_leader_shipments_path, alert: "Nie udało się cofnąć statusu wysyłki"
      end
    end

    def download_waybill
      unless @shipment.apaczka_order_id.present?
        redirect_to warehouse_leader_shipments_path, alert: "Brak ID zamówienia w aPaczka"
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
        redirect_to warehouse_leader_shipments_path, alert: "Nie udało się pobrać listu przewozowego"
      end
    end

    private

    def set_shipment
      @shipment = Shipment.includes(order: [:user, :area_group]).find(params[:id])
    end
  end
end
