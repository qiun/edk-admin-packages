class AddPosterFieldsToAllocationChanges < ActiveRecord::Migration[8.1]
  def change
    add_column :allocation_changes, :previous_allocated_posters, :integer
    add_column :allocation_changes, :new_allocated_posters, :integer
    add_column :allocation_changes, :previous_distributed_posters, :integer
    add_column :allocation_changes, :new_distributed_posters, :integer
  end
end
