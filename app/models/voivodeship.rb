class Voivodeship < ApplicationRecord
  # Associations
  has_many :users, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
end
