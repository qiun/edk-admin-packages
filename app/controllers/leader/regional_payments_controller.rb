module Leader
  class RegionalPaymentsController < Leader::BaseController
    before_action :set_edition
    before_action :set_region
    before_action :authorize_region!
    before_action :set_payment, only: [ :show, :destroy ]

    def index
      @payments = @region.regional_payments.for_edition(@edition).recent
    end

    def new
      @payment = @region.regional_payments.new(
        edition: @edition,
        payment_date: Date.current
      )
    end

    def create
      @payment = @region.regional_payments.new(payment_params)
      @payment.edition = @edition
      @payment.recorded_by = current_user

      if @payment.save
        redirect_to leader_region_regional_payment_path(@region, @payment),
                    notice: "Płatność zapisana"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      # Display payment details
    end

    def destroy
      if @payment.destroy
        redirect_to leader_region_regional_payments_path(@region),
                    notice: "Płatność usunięta"
      else
        redirect_to leader_region_regional_payment_path(@region, @payment),
                    alert: "Nie można usunąć płatności: #{@payment.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_edition
      @edition = Edition.find_by(is_active: true) || Edition.last
    end

    def set_region
      @region = Region.find(params[:region_id])
    end

    def authorize_region!
      unless current_user.area_groups.include?(@region.area_group)
        redirect_to leader_regions_path,
                    alert: "Nie masz uprawnień do tego rejonu"
      end
    end

    def set_payment
      @payment = @region.regional_payments.find(params[:id])
    end

    def payment_params
      params.require(:regional_payment).permit(:amount, :payment_date,
                                               :notes, :confirmation)
    end
  end
end
