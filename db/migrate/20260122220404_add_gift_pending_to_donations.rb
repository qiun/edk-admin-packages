class AddGiftPendingToDonations < ActiveRecord::Migration[8.1]
  def change
    add_column :donations, :gift_pending, :boolean, default: false, null: false
  end
end
