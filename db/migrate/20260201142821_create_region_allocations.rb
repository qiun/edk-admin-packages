class CreateRegionAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :region_allocations do |t|
      t.references :region, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.integer :allocated_quantity, default: 0, null: false
      t.integer :sold_quantity, default: 0, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps

      t.index [ :region_id, :edition_id ], unique: true,
              name: 'index_region_allocations_on_region_edition'
    end
  end
end
