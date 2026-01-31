module Admin
  class ReturnsController < Admin::BaseController
    before_action :require_admin! # Only admins can manage returns
    before_action :set_return, only: [ :show, :update, :approve, :reject, :mark_received ]

    def index
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @returns = Return.for_edition(@edition)
                       .includes(:user)
                       .order(created_at: :desc)

      @returns = @returns.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def update
      if @return.update(return_params)
        redirect_to admin_return_path(@return), notice: "Zwrot został zaktualizowany"
      else
        render :show, status: :unprocessable_entity
      end
    end

    def approve
      @return.approve!
      redirect_to admin_return_path(@return), notice: "Zwrot został zatwierdzony"
    end

    def reject
      @return.reject!(params[:reason])
      redirect_to admin_return_path(@return), notice: "Zwrot został odrzucony"
    end

    def mark_received
      @return.mark_received!
      redirect_to admin_return_path(@return), notice: "Zwrot został przyjęty do magazynu"
    end

    private

    def set_return
      @return = Return.find(params[:id])
    end

    def return_params
      params.require(:return).permit(:notes)
    end
  end
end
