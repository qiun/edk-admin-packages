module Warehouse
  class ShipmentsController < Warehouse::BaseController
    def index
      @shipments = Shipment.includes(order: :user, donation: [])
                          .order(created_at: :desc)

      # Default: show only paid donations if no filters are specified
      if params[:type].blank? && params[:payment_status].blank?
        @shipments = @shipments.joins(:donation).where(donations: { payment_status: :paid })
      else
        # Filter by type (order vs donation)
        if params[:type] == "donation"
          @shipments = @shipments.where.not(donation_id: nil)
        elsif params[:type] == "order"
          @shipments = @shipments.where.not(order_id: nil)
        end

        # Filter by payment status (for donations)
        if params[:payment_status].present?
          @shipments = @shipments.joins(:donation).where(donations: { payment_status: params[:payment_status] })
        end
      end

      # Filter by shipment status
      @shipments = @shipments.where(status: params[:status]) if params[:status].present?
    end

    def show
      @shipment = Shipment.includes(order: [:user, :area_group], donation: []).find(params[:id])
    end
  end
end
