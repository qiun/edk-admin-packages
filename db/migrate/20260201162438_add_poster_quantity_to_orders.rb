class AddPosterQuantityToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :poster_quantity, :integer, default: 0, null: false
    add_index :orders, :poster_quantity
  end
end
