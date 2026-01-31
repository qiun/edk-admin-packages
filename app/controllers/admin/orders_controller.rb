module Admin
  class OrdersController < Admin::BaseController
    before_action :require_admin! # Only admins, warehouse has their own namespace
    before_action :set_order, only: [ :show, :confirm, :cancel, :print_label ]

    def index
      @orders = Order.for_edition(current_edition)
                     .includes(:user, :shipment, :area_group)
                     .order(created_at: :desc)

      @orders = @orders.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def confirm
      if @order.pending?
        @order.confirm!
        redirect_to admin_order_path(@order), notice: "Zamówienie zostało potwierdzone"
      else
        redirect_to admin_order_path(@order), alert: "Nie można potwierdzić zamówienia o statusie: #{@order.status}"
      end
    end

    def cancel
      if @order.pending? || @order.confirmed?
        @order.cancel!
        redirect_to admin_order_path(@order), notice: "Zamówienie zostało anulowane"
      else
        redirect_to admin_order_path(@order), alert: "Nie można anulować zamówienia o statusie: #{@order.status}"
      end
    end

    def print_label
      if @order.shipment&.label_pdf.present?
        send_data @order.shipment.label_pdf,
                  filename: "etykieta-#{@order.id}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      else
        redirect_to admin_order_path(@order), alert: "Etykieta nie jest jeszcze dostępna"
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end
  end
end
