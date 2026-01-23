class Return < ApplicationRecord
  belongs_to :user
  belongs_to :edition

  enum :status, {
    requested: "requested",
    approved: "approved",
    shipped: "shipped",
    received: "received",
    rejected: "rejected"
  }

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :pending, -> { where(status: [ :requested, :approved, :shipped ]) }

  def approve!
    update!(status: :approved)
  end

  def mark_received!
    transaction do
      update!(status: :received, received_at: Time.current)
      edition.inventory.receive_return(quantity, reference: self)
    end
  end

  def reject!(reason = nil)
    update!(status: :rejected, notes: reason)
  end
end
