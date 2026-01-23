class CreateLeaderSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :leader_settings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.decimal :custom_price, precision: 8, scale: 2
      t.boolean :ordering_locked, default: false

      t.timestamps
    end

    add_index :leader_settings, [:user_id, :edition_id], unique: true
  end
end
