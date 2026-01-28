class AddCheckDonationInventoryToEditions < ActiveRecord::Migration[8.1]
  def change
    add_column :editions, :check_donation_inventory, :boolean, default: false, null: false
  end
end
