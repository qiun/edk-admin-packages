class AddPosterQuantityToRegionTransfers < ActiveRecord::Migration[8.1]
  def change
    add_column :region_transfers, :poster_quantity, :integer, default: 0, null: false
    add_index :region_transfers, :poster_quantity
  end
end
