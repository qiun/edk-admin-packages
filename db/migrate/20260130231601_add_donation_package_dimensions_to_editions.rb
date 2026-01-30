class AddDonationPackageDimensionsToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :donation_package_length, :decimal, precision: 5, scale: 1, default: 19.0, null: false
    add_column :editions, :donation_package_width, :decimal, precision: 5, scale: 1, default: 38.0, null: false
    add_column :editions, :donation_package_height, :decimal, precision: 5, scale: 1, default: 64.0, null: false
    add_column :editions, :donation_package_max_weight, :decimal, precision: 5, scale: 2, default: 1.0, null: false
  end
end
