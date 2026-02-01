module Leader
  class RegionsController < Leader::BaseController
    before_action :set_edition
    before_action :set_region, only: [ :show, :edit, :update, :destroy ]

    def index
      @regions = current_user.area_groups
                            .flat_map { |ag| ag.regions.for_edition(@edition) }
                            .sort_by(&:name)
    end

    def show
      @allocation = @region.region_allocations.find_by(edition: @edition)
      @payments = @region.regional_payments.order(payment_date: :desc)
      @transfers_from = @region.transfers_from.where(edition: @edition)
      @transfers_to = @region.transfers_to.where(edition: @edition)
    end

    def new
      @region = Region.new(edition: @edition)
    end

    def create
      @region = Region.new(region_params)
      @region.edition = @edition
      @region.created_by = current_user

      # Walidacja: czy user ma uprawnienia do tego area_group
      unless current_user.area_groups.include?(@region.area_group)
        redirect_to leader_regions_path, alert: "Nie masz uprawnień do tego okręgu"
        return
      end

      if @region.save
        redirect_to leader_region_path(@region), notice: "Rejon utworzony"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize_region!
    end

    def update
      authorize_region!

      if @region.update(region_params)
        redirect_to leader_region_path(@region), notice: "Rejon zaktualizowany"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize_region!

      if @region.destroy
        redirect_to leader_regions_path, notice: "Rejon usunięty"
      else
        redirect_to leader_region_path(@region),
                    alert: "Nie można usunąć rejonu: #{@region.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_edition
      @edition = Edition.find_by(is_active: true) || Edition.last
    end

    def set_region
      @region = Region.find(params[:id])
    end

    def authorize_region!
      unless current_user.area_groups.include?(@region.area_group)
        redirect_to leader_regions_path, alert: "Nie masz uprawnień do tego rejonu"
      end
    end

    def region_params
      params.require(:region).permit(:name, :contact_person, :phone, :email,
                                     :notes, :area_group_id)
    end
  end
end
