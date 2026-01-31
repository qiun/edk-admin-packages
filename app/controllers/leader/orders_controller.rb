module Leader
  class OrdersController < Leader::BaseController
    before_action :check_ordering_allowed, only: [ :new, :create ]
    before_action :set_order, only: [ :show, :edit, :update, :cancel ]
    before_action :ensure_order_editable, only: [ :edit, :update, :cancel ]

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
        # Inventory reservation happens in after_create callback
        redirect_to leader_order_path(@order), notice: "Zamówienie zostało złożone pomyślnie"
      else
        # Log validation errors for debugging
        Rails.logger.error "Order validation failed: #{@order.errors.full_messages.join(', ')}"
        @price_per_unit = @order.price_per_unit
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @price_per_unit = @order.price_per_unit
    end

    def update
      old_quantity = @order.quantity
      new_quantity = order_params[:quantity].to_i

      begin
        # Najpierw aktualizuj ilość (z obsługą rezerwacji)
        if new_quantity != old_quantity
          @order.update_quantity!(new_quantity)
        end

        # Potem zaktualizuj dane paczkomatu
        if @order.update(order_params.except(:quantity))
          redirect_to leader_order_path(@order), notice: "Zamówienie zostało zaktualizowane"
        else
          @price_per_unit = @order.price_per_unit
          render :edit, status: :unprocessable_entity
        end
      rescue Inventory::InsufficientStock => e
        @order.errors.add(:quantity, "Niewystarczająca ilość pakietów na magazynie")
        @price_per_unit = @order.price_per_unit
        render :edit, status: :unprocessable_entity
      end
    end

    def cancel
      @order.cancel!

      # Wyślij powiadomienie email do adminów
      OrderMailer.cancelled_by_leader(@order).deliver_later

      redirect_to leader_orders_path, notice: "Zamówienie zostało anulowane"
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

    def ensure_order_editable
      unless @order.can_be_edited_by_leader?
        redirect_to leader_order_path(@order), alert: "To zamówienie nie może być edytowane - zostało już potwierdzone przez koordynatora"
      end
    end
  end
end
