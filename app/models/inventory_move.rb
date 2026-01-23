class InventoryMove < ApplicationRecord
  belongs_to :inventory
  belongs_to :created_by, class_name: "User", optional: true

  # Polymorphic reference to Order, Donation, or Return
  belongs_to :reference, polymorphic: true, optional: true

  enum :move_type, {
    stock_in: "stock_in",
    stock_out: "stock_out",
    reserve: "reserve",
    release: "release",
    ship: "ship",
    return_received: "return_received",
    adjustment: "adjustment"
  }

  validates :move_type, presence: true
  validates :quantity, presence: true, numericality: { other_than: 0 }

  scope :recent, -> { order(created_at: :desc) }
end
