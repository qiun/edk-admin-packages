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
        completed: @returns.where(status: :received).count
      }
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

      # Can return packages from shipped/delivered orders
      # minus packages already in return process or completed
      shipped_quantity = orders.where(status: [:shipped, :delivered]).sum(:quantity)
      already_returned = returns.where(status: [:requested, :approved, :shipped, :received]).sum(:quantity)

      shipped_quantity - already_returned
    end
  end
end
