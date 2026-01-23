class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :edition, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :area_group, foreign_key: true
      t.integer :quantity, null: false
      t.string :status, default: 'pending'
      t.string :locker_code
      t.string :locker_name
      t.string :locker_address
      t.string :locker_city
      t.string :locker_post_code
      t.decimal :price_per_unit, precision: 8, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, [:edition_id, :status]
  end
end
