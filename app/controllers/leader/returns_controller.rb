module Leader
  class ReturnsController < Leader::BaseController
    before_action :set_return, only: [:show]

    def index
      @edition = current_edition
      @returns = current_user.returns
                             .for_edition(@edition)
                             .order(created_at: :desc)

      @summary = {
        pending: @returns.where(status: :requested).count,
        approved: @returns.where(status: :approved).count,
        completed: @returns.where(status: :received).count,
        total_quantity: @returns.where(status: [:requested, :approved, :shipped, :received]).sum(:quantity)
      }
      @can_create_return = calculate_max_returnable > 0
    end

    def show
    end

    def new
      @return = current_user.returns.new(edition: current_edition)
      @max_quantity = calculate_max_returnable

      if @max_quantity <= 0
        redirect_to leader_returns_path, alert: "Brak pakietów do zwrotu"
      end
    end

    def create
      @return = current_user.returns.new(return_params)
      @return.edition = current_edition
      @return.status = :requested

      if @return.save
        # Send notification to admin
        # TODO: AdminMailer.return_requested(@return).deliver_later

        redirect_to leader_returns_path, notice: "Zgłoszenie zwrotu zostało wysłane do koordynatora"
      else
        @max_quantity = calculate_max_returnable
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_return
      @return = current_user.returns.find(params[:id])
    end

    def return_params
      params.require(:return).permit(:quantity, :reason, :locker_code, :locker_name, :notes)
    end

    def calculate_max_returnable
      edition = current_edition
      orders = current_user.orders.for_edition(edition)
      returns = current_user.returns.where(edition: edition)

      # Can return packages from orders that have:
      # - status shipped/delivered OR
      # - status confirmed with a shipment that is shipped/delivered
      # minus packages already in return process or completed
      delivered_quantity = orders.where(status: [:shipped, :delivered]).sum(:quantity)

      confirmed_with_shipment = orders.where(status: :confirmed)
                                      .joins(:shipment)
                                      .where(shipments: { status: %w[label_ready picked_up in_transit ready_for_pickup delivered] })
                                      .sum(:quantity)

      total_available = delivered_quantity + confirmed_with_shipment
      already_returned = returns.where(status: [:requested, :approved, :shipped, :received]).sum(:quantity)

      total_available - already_returned
    end
  end
end
