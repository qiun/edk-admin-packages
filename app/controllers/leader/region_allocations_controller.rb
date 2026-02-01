module Leader
  class RegionAllocationsController < Leader::BaseController
    before_action :set_edition
    before_action :set_region
    before_action :authorize_region!
    before_action :set_or_create_allocation

    def edit
      # Form for editing allocation
    end

    def update
      # Store change reason in Current for the callback
      Current.user = current_user
      Current.change_reason = allocation_params[:change_reason]

      if @allocation.update(allocation_params.except(:change_reason))
        redirect_to leader_region_path(@region),
                    notice: "Przydzielenie pakietów zaktualizowane"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def history
      @changes = @allocation.allocation_changes.recent.includes(:changed_by)
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

    def set_or_create_allocation
      @allocation = @region.region_allocations.find_or_initialize_by(
        edition: @edition
      )

      if @allocation.new_record?
        @allocation.created_by = current_user
        @allocation.save!
      end
    end

    def allocation_params
      params.require(:region_allocation).permit(
        :allocated_quantity,
        :sold_quantity,
        :allocated_posters,
        :distributed_posters,
        :change_reason
      )
    end
  end
end
