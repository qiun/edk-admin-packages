class CreateSalesReports < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.integer :quantity_sold, null: false
      t.datetime :reported_at, null: false
      t.text :notes

      t.timestamps
    end
  end
end
