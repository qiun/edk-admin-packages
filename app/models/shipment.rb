class Shipment < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :donation, optional: true

  enum :status, {
    pending: "pending",
    label_printed: "label_printed",
    shipped: "shipped",
    in_transit: "in_transit",
    delivered: "delivered",
    failed: "failed"
  }

  validates :status, presence: true
  validate :must_have_order_or_donation

  scope :recent, -> { order(created_at: :desc) }

  def source
    order || donation
  end

  private

  def must_have_order_or_donation
    if order.blank? && donation.blank?
      errors.add(:base, "Shipment must belong to an order or donation")
    end
  end
end
