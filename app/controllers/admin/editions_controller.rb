module Admin
  class EditionsController < Admin::BaseController
    before_action :set_edition, only: [ :show, :edit, :update, :destroy, :activate, :lock_ordering, :unlock_ordering ]

    def index
      @editions = Edition.recent
    end

    def show
    end

    def new
      @edition = Edition.new(year: Date.current.year + 1)
    end

    def create
      @edition = Edition.new(edition_params)

      if @edition.save
        redirect_to admin_edition_path(@edition), notice: "Edycja została utworzona"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @edition.update(edition_params)
        redirect_to admin_edition_path(@edition), notice: "Edycja została zaktualizowana"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @edition.orders.any? || @edition.donations.any?
        redirect_to admin_editions_path, alert: "Nie można usunąć edycji z zamówieniami lub darowiznami"
      else
        @edition.destroy
        redirect_to admin_editions_path, notice: "Edycja została usunięta"
      end
    end

    def activate
      @edition.activate!
      redirect_to admin_edition_path(@edition), notice: "Edycja została aktywowana"
    end

    def lock_ordering
      @edition.lock_ordering!
      redirect_to admin_edition_path(@edition), notice: "Zamawianie zostało zablokowane"
    end

    def unlock_ordering
      @edition.unlock_ordering!
      redirect_to admin_edition_path(@edition), notice: "Zamawianie zostało odblokowane"
    end

    private

    def set_edition
      @edition = Edition.find(params[:id])
    end

    def edition_params
      params.require(:edition).permit(:name, :year, :status, :default_price, :donor_price, :ordering_locked, :check_donation_inventory)
    end
  end
end
