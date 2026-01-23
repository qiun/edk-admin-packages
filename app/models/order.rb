class Order < ApplicationRecord
  belongs_to :edition
  belongs_to :user
  belongs_to :area_group, optional: true
  has_one :shipment, dependent: :destroy

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 10 }
  validates :locker_code, :locker_name, presence: true

  validate :ordering_not_locked, on: :create
  validate :sufficient_inventory, on: :create

  before_create :set_price
  after_create :reserve_inventory

  scope :for_edition, ->(edition) { where(edition: edition) }

  def confirm!
    transaction do
      update!(status: :confirmed, confirmed_at: Time.current)
      # Will be implemented in Phase 4: Apaczka::CreateShipmentJob.perform_later(self)
    end
  end

  def cancel!
    transaction do
      update!(status: :cancelled)
      edition.inventory.release_reserved(quantity)
    end
  end

  private

  def ordering_not_locked
    if user&.ordering_locked_for?(edition)
      errors.add(:base, "Zamawianie pakietów jest zablokowane")
    end
  end

  def sufficient_inventory
    return unless edition&.inventory

    if edition.inventory.available < quantity
      errors.add(:quantity, "Niewystarczająca ilość pakietów na magazynie")
    end
  end

  def set_price
    self.price_per_unit = user.effective_price_for(edition)
    self.total_amount = quantity * price_per_unit
  end

  def reserve_inventory
    edition.inventory.reserve(quantity)
  end
end
