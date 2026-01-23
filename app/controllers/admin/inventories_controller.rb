module Admin
  class InventoriesController < Admin::BaseController
    before_action :set_inventory

    def show
      @moves = @inventory.inventory_moves.recent.limit(20)
    end

    def edit
    end

    def update
      if @inventory.update(inventory_params)
        redirect_to admin_inventory_path, notice: "Magazyn został zaktualizowany"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def add_stock
      quantity = params[:quantity].to_i
      notes = params[:notes]

      if quantity > 0
        @inventory.add_stock(quantity, notes: notes, user: current_user)
        redirect_to admin_inventory_path, notice: "Dodano #{quantity} pakietów do magazynu"
      else
        redirect_to admin_inventory_path, alert: "Ilość musi być większa od 0"
      end
    end

    def movements
      @moves = @inventory.inventory_moves.recent.includes(:created_by)
    end

    private

    def set_inventory
      @inventory = current_edition&.inventory
      redirect_to admin_root_path, alert: "Brak aktywnej edycji" unless @inventory
    end

    def inventory_params
      params.require(:inventory).permit(:total_stock, :available, :reserved, :shipped, :returned)
    end
  end
end
