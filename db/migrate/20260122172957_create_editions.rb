class CreateEditions < ActiveRecord::Migration[8.1]
  def change
    create_table :editions do |t|
      t.string :name, null: false
      t.integer :status, null: false, default: 0  # 0: draft, 1: active, 2: closed
      t.integer :year, null: false
      t.decimal :package_price, precision: 10, scale: 2, null: false, default: 50.0
      t.decimal :leader_price, precision: 10, scale: 2  # Optional: custom price per leader
      t.integer :inventory, null: false, default: 0

      t.timestamps
    end

    add_index :editions, :status
    add_index :editions, :year
  end
end
