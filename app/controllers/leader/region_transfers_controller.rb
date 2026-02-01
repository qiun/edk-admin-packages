module Leader
  class RegionTransfersController < Leader::BaseController
    before_action :set_edition
    before_action :set_transfer, only: [ :show, :destroy ]

    def index
      # Get all regions from user's area_groups for filtering
      region_ids = current_user.area_groups.flat_map do |ag|
        ag.regions.for_edition(@edition).pluck(:id)
      end

      @transfers = RegionTransfer.for_edition(@edition)
                                  .where("from_region_id IN (?) OR to_region_id IN (?)",
                                         region_ids, region_ids)
                                  .includes(:from_region, :to_region, :transferred_by)
                                  .recent
    end

    def new
      @transfer = RegionTransfer.new(edition: @edition)
      @available_regions = current_user.area_groups
                                       .flat_map { |ag| ag.regions.for_edition(@edition) }
                                       .sort_by(&:name)
    end

    def create
      @transfer = RegionTransfer.new(transfer_params)
      @transfer.edition = @edition
      @transfer.transferred_by = current_user

      # Walidacja: czy user ma uprawnienia do from_region
      unless current_user.area_groups.include?(@transfer.from_region.area_group)
        redirect_to leader_region_transfers_path,
                    alert: "Nie masz uprawnień do rejonu źródłowego"
        return
      end

      if @transfer.save
        redirect_to leader_region_transfer_path(@transfer),
                    notice: "Transfer utworzony"
      else
        @available_regions = current_user.area_groups
                                         .flat_map { |ag| ag.regions.for_edition(@edition) }
                                         .sort_by(&:name)
        render :new, status: :unprocessable_entity
      end
    end

    def show
      authorize_transfer!
    end

    def destroy
      authorize_transfer!

      unless @transfer.pending?
        redirect_to leader_region_transfer_path(@transfer),
                    alert: "Można usunąć tylko oczekujące transfery"
        return
      end

      if @transfer.destroy
        redirect_to leader_region_transfers_path,
                    notice: "Transfer usunięty"
      else
        redirect_to leader_region_transfer_path(@transfer),
                    alert: "Nie można usunąć transferu: #{@transfer.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_edition
      @edition = Edition.find_by(is_active: true) || Edition.last
    end

    def set_transfer
      @transfer = RegionTransfer.find(params[:id])
    end

    def authorize_transfer!
      from_authorized = current_user.area_groups.include?(@transfer.from_region.area_group)
      to_authorized = current_user.area_groups.include?(@transfer.to_region.area_group)

      unless from_authorized || to_authorized
        redirect_to leader_region_transfers_path,
                    alert: "Nie masz uprawnień do tego transferu"
      end
    end

    def transfer_params
      params.require(:region_transfer).permit(
        :from_region_id,
        :to_region_id,
        :quantity,
        :poster_quantity,
        :reason
      )
    end
  end
end
