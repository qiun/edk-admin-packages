class CreateAllocationChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :allocation_changes do |t|
      t.references :region_allocation, null: false, foreign_key: true
      t.integer :previous_allocated
      t.integer :new_allocated
      t.integer :previous_sold
      t.integer :new_sold
      t.references :changed_by, null: false, foreign_key: { to_table: :users }
      t.text :reason

      t.timestamps
    end
  end
end
