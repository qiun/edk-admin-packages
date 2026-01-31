module Admin
  class InventoryController < Admin::BaseController
    def show
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @inventory = @edition.inventory || @edition.create_inventory!(
        total_stock: 0,
        available: 0,
        reserved: 0,
        shipped: 0,
        returned: 0
      )
      @recent_moves = @inventory.inventory_moves.order(created_at: :desc).limit(10)
    end

    def edit
      @inventory = current_edition.inventory
    end

    def update
      @inventory = current_edition.inventory

      if @inventory.update(inventory_params)
        redirect_to admin_inventory_path, notice: "Magazyn został zaktualizowany"
      else
        render :edit
      end
    end

    def add_stock
      @inventory = current_edition.inventory
      quantity = params[:quantity].to_i
      notes = params[:notes]

      begin
        @inventory.add_stock(quantity, notes: notes, user: current_user)
        redirect_to admin_inventory_path, notice: "Dodano #{quantity} pakietów do magazynu"
      rescue => e
        redirect_to admin_inventory_path, alert: "Błąd: #{e.message}"
      end
    end

    def movements
      @edition = params[:edition_id] ? Edition.find(params[:edition_id]) : current_edition
      @inventory = @edition.inventory
      @moves = @inventory.inventory_moves.order(created_at: :desc)
    end

    private

    def inventory_params
      params.require(:inventory).permit(:total_stock, :available, :reserved, :shipped, :returned)
    end
  end
end
