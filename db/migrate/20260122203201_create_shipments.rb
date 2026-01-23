class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :order, foreign_key: true
      t.references :donation, foreign_key: true
      t.string :apaczka_order_id
      t.string :waybill_number
      t.string :tracking_url
      t.binary :label_pdf
      t.string :status, default: 'pending'
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.json :apaczka_response

      t.timestamps
    end

    add_index :shipments, :status
    add_index :shipments, :apaczka_order_id
    add_index :shipments, :waybill_number
  end
end
