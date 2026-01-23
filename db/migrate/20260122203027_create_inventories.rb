class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :edition, null: false, foreign_key: true, index: { unique: true }
      t.integer :total_stock, default: 0
      t.integer :available, default: 0
      t.integer :reserved, default: 0
      t.integer :shipped, default: 0
      t.integer :returned, default: 0

      t.timestamps
    end
  end
end
