class CreateReturns < ActiveRecord::Migration[8.1]
  def change
    create_table :returns do |t|
      t.references :user, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :status, default: 'requested'
      t.string :locker_code
      t.string :locker_name
      t.text :notes
      t.datetime :received_at

      t.timestamps
    end

    add_index :returns, :status
  end
end
