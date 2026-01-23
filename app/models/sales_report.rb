class SalesReport < ApplicationRecord
  belongs_to :user
  belongs_to :edition

  validates :quantity_sold, presence: true, numericality: { greater_than: 0 }
  validates :reported_at, presence: true

  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :recent, -> { order(reported_at: :desc) }
end
