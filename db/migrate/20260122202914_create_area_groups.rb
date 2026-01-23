class CreateAreaGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :area_groups do |t|
      t.references :leader, foreign_key: { to_table: :users }
      t.references :edition, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
