class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.integer :total_sent, default: 0
      t.integer :total_returned, default: 0
      t.integer :total_sold, default: 0
      t.decimal :price_per_unit, precision: 8, scale: 2
      t.decimal :amount_due, precision: 10, scale: 2
      t.decimal :amount_paid, precision: 10, scale: 2, default: 0
      t.string :status, default: 'pending'
      t.datetime :settled_at

      t.timestamps
    end

    add_index :settlements, [:user_id, :edition_id], unique: true
    add_index :settlements, :status
  end
end
