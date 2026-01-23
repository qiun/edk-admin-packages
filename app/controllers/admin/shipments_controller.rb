module Admin
  class ShipmentsController < Admin::BaseController
    before_action :set_shipment, only: [ :show, :refresh_status ]

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

    private

    def set_shipment
      @shipment = Shipment.find(params[:id])
    end
  end
end
