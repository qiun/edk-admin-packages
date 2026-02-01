class CreateRegionTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :region_transfers do |t|
      t.references :from_region, null: false, foreign_key: { to_table: :regions }
      t.references :to_region, null: false, foreign_key: { to_table: :regions }
      t.references :edition, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :status, default: "pending", null: false
      t.text :reason
      t.references :transferred_by, null: false, foreign_key: { to_table: :users }
      t.datetime :transferred_at

      t.timestamps
    end
  end
end
