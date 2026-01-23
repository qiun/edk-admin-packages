class CreateInventoryMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_moves do |t|
      t.references :inventory, null: false, foreign_key: true
      t.string :move_type, null: false
      t.integer :quantity, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :inventory_moves, [:reference_type, :reference_id]
  end
end
