class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :edition, null: false, foreign_key: true
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.integer :quantity, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.string :locker_code
      t.string :locker_name
      t.string :locker_address
      t.string :locker_city
      t.string :locker_post_code
      t.string :payment_status, default: 'pending'
      t.string :payment_id
      t.string :payment_transaction_id

      t.timestamps
    end

    add_index :donations, :payment_status
    add_index :donations, :payment_id
  end
end
