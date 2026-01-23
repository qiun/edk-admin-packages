class FixEditionFields < ActiveRecord::Migration[8.1]
  def up
    # Remove old fields (only if they exist)
    remove_column :editions, :package_price if column_exists?(:editions, :package_price)
    remove_column :editions, :leader_price if column_exists?(:editions, :leader_price)
    remove_column :editions, :inventory if column_exists?(:editions, :inventory)

    # Change status from integer to string (only if it's not already a string)
    if column_exists?(:editions, :status) && columns(:editions).find { |c| c.name == 'status' }.type != :string
      change_column :editions, :status, :string, default: 'draft'
    end

    # Add new fields per plan (only if they don't exist)
    add_column :editions, :is_active, :boolean, default: false unless column_exists?(:editions, :is_active)
    add_column :editions, :ordering_locked, :boolean, default: false unless column_exists?(:editions, :ordering_locked)
    add_column :editions, :default_price, :decimal, precision: 8, scale: 2, default: 30.0 unless column_exists?(:editions, :default_price)
    add_column :editions, :donor_price, :decimal, precision: 8, scale: 2, default: 50.0 unless column_exists?(:editions, :donor_price)

    # Update indexes (only if they don't already exist)
    add_index :editions, :year, unique: true unless index_exists?(:editions, :year)
    add_index :editions, :is_active unless index_exists?(:editions, :is_active)
  end

  def down
    # This migration is not reversible
    raise ActiveRecord::IrreversibleMigration
  end
end
