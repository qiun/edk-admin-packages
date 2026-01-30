class AddPackageDimensionsToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :order_package_length, :decimal, precision: 5, scale: 1, default: 41.0, null: false
    add_column :editions, :order_package_width, :decimal, precision: 5, scale: 1, default: 38.0, null: false
    add_column :editions, :order_package_height, :decimal, precision: 5, scale: 1, default: 64.0, null: false
    add_column :editions, :order_package_max_weight, :decimal, precision: 5, scale: 2, default: 30.0, null: false
  end
end
