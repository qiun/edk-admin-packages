class AddVoivodeshipToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :voivodeship, :string
  end
end
