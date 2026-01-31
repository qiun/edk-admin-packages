class ReplaceVoivodeshipWithVoivodeshipIdInUsers < ActiveRecord::Migration[8.1]
  def up
    # Add voivodeship_id column
    add_reference :users, :voivodeship, foreign_key: true, index: true

    # Migrate existing data from voivodeship (string) to voivodeship_id (integer)
    User.reset_column_information
    User.find_each do |user|
      next if user.voivodeship.blank?

      voivodeship = Voivodeship.find_by(name: user.voivodeship.strip)
      user.update_column(:voivodeship_id, voivodeship.id) if voivodeship
    end

    # Remove old voivodeship column
    remove_column :users, :voivodeship, :string
  end

  def down
    # Add back the string column
    add_column :users, :voivodeship, :string

    # Migrate data back
    User.reset_column_information
    User.find_each do |user|
      next if user.voivodeship_id.blank?

      voivodeship = Voivodeship.find_by(id: user.voivodeship_id)
      user.update_column(:voivodeship, voivodeship.name) if voivodeship
    end

    # Remove the reference column
    remove_reference :users, :voivodeship, foreign_key: true, index: true
  end
end
