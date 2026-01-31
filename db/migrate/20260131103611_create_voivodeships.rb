class CreateVoivodeships < ActiveRecord::Migration[8.1]
  def change
    create_table :voivodeships do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :voivodeships, :name, unique: true

    # Seed voivodeships data during migration
    reversible do |dir|
      dir.up do
        [
          "dolnośląskie",
          "kujawsko-pomorskie",
          "lubelskie",
          "lubuskie",
          "łódzkie",
          "małopolskie",
          "mazowieckie",
          "opolskie",
          "podkarpackie",
          "podlaskie",
          "pomorskie",
          "śląskie",
          "świętokrzyskie",
          "warmińsko-mazurskie",
          "wielkopolskie",
          "zachodniopomorskie"
        ].each do |voivodeship_name|
          execute <<-SQL
            INSERT INTO voivodeships (name, created_at, updated_at)
            VALUES ('#{voivodeship_name}', NOW(), NOW())
            ON CONFLICT (name) DO NOTHING;
          SQL
        end
      end
    end
  end
end
