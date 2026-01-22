class Edition < ApplicationRecord
  # Enums
  enum :status, { draft: 0, active: 1, closed: 2 }

  # Validations
  validates :name, presence: true
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :package_price, presence: true, numericality: { greater_than: 0 }
  validates :inventory, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_year, ->(year) { where(year: year) }
  scope :recent, -> { order(year: :desc, created_at: :desc) }

  # Associations (to be added in later phases)
  # has_many :orders
  # has_many :inventory_transactions
end
