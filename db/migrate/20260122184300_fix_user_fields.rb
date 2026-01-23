class FixUserFields < ActiveRecord::Migration[8.1]
  def up
    # Remove old fields
    remove_column :users, :name
    remove_column :users, :okręg_id

    # Add new fields per plan
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone, :string
    add_reference :users, :created_by, foreign_key: { to_table: :users }

    # Change role from integer to string
    change_column :users, :role, :string, default: 'leader'

    add_index :users, :role unless index_exists?(:users, :role)
  end

  def down
    # This migration is not reversible
    raise ActiveRecord::IrreversibleMigration
  end
end
