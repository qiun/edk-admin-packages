class AddGiftFieldsToDonations < ActiveRecord::Migration[8.0]
  def change
    add_column :donations, :title, :string
    add_column :donations, :want_gift, :boolean, default: false
    add_column :donations, :terms_accepted, :boolean, default: false
  end
end
