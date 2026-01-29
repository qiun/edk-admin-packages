module Leader
  class OrdersController < Leader::BaseController
    before_action :check_ordering_allowed, only: [:new, :create]
    before_action :set_order, only: [:show]

    def index
      @edition = current_edition
      @orders = current_user.orders
                            .for_edition(@edition)
                            .includes(:shipment)
                            .order(created_at: :desc)
      @can_order = !current_user.ordering_locked_for?(@edition)
    end

    def show
    end

    def new
      @order = current_user.orders.new(edition: current_edition)
      @price_per_unit = current_user.effective_price_for(current_edition)
    end

    def create
      @order = current_user.orders.new(order_params)
      @order.edition = current_edition
      @order.price_per_unit = current_user.effective_price_for(current_edition)
      @order.total_amount = @order.quantity * @order.price_per_unit

      if @order.save
        # Reserve inventory
        current_edition.inventory.reserve(@order.quantity, reference: @order)

        redirect_to leader_order_path(@order), notice: "Zamówienie zostało złożone pomyślnie"
      else
        # Log validation errors for debugging
        Rails.logger.error "Order validation failed: #{@order.errors.full_messages.join(', ')}"
        @price_per_unit = @order.price_per_unit
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_order
      @order = current_user.orders.find(params[:id])
    end

    def order_params
      params.require(:order).permit(
        :quantity,
        :locker_code,
        :locker_name,
        :locker_address,
        :locker_city,
        :locker_post_code
      )
    end

    def check_ordering_allowed
      if current_user.ordering_locked_for?(current_edition)
        redirect_to leader_orders_path, alert: "Zamawianie zostało zablokowane przez koordynatora"
      end
    end
  end
end
