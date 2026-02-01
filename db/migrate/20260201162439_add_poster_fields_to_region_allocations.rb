class AddPosterFieldsToRegionAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :region_allocations, :allocated_posters, :integer, default: 0, null: false
    add_index :region_allocations, :allocated_posters
    add_column :region_allocations, :distributed_posters, :integer, default: 0, null: false
    add_index :region_allocations, :distributed_posters
  end
end
