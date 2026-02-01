class CreateRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :regions do |t|
      t.string :name, null: false
      t.string :contact_person
      t.string :phone
      t.string :email
      t.text :notes
      t.references :area_group, null: false, foreign_key: true
      t.references :edition, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index [ :area_group_id, :edition_id, :name ], unique: true,
              name: 'index_regions_on_area_edition_name'
    end
  end
end
