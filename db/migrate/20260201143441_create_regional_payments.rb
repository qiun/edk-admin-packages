class CreateRegionalPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :regional_payments do |t|
      t.references :region, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :payment_date, null: false
      t.text :notes
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
