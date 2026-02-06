module Admin
  class AreaGroupsController < Admin::BaseController
    before_action :require_admin!
    before_action :set_area_group, only: [ :edit, :update, :destroy ]

    def index
      @edition = current_edition
      @area_groups = AreaGroup.includes(:leader, :edition, :regions, :voivodeship)
                              .where(edition: @edition)
                              .order(:name)
    end

    def new
      @area_group = AreaGroup.new(edition: current_edition)
      @leaders = User.where(role: :leader).order(:last_name, :first_name)
    end

    def create
      @area_group = AreaGroup.new(area_group_params)

      if @area_group.save
        redirect_to admin_area_groups_path, notice: "Okręg został utworzony"
      else
        @leaders = User.where(role: :leader).order(:last_name, :first_name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @leaders = User.where(role: :leader).order(:last_name, :first_name)
    end

    def update
      if @area_group.update(area_group_params)
        redirect_to admin_area_groups_path, notice: "Okręg został zaktualizowany"
      else
        @leaders = User.where(role: :leader).order(:last_name, :first_name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @area_group.regions.any?
        redirect_to admin_area_groups_path, alert: "Nie można usunąć okręgu z przypisanymi rejonami"
      else
        @area_group.destroy
        redirect_to admin_area_groups_path, notice: "Okręg został usunięty"
      end
    end

    private

    def set_area_group
      @area_group = AreaGroup.find(params[:id])
    end

    def area_group_params
      params.require(:area_group).permit(:name, :description, :leader_id, :edition_id, :voivodeship_id)
    end
  end
end
