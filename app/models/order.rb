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
  validates :poster_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false
  validates :locker_code, :locker_name, presence: true

  validate :ordering_not_locked, on: :create
  validate :sufficient_inventory, on: :create

  before_create :set_price
  after_create :reserve_inventory

  scope :for_edition, ->(edition) { where(edition: edition) }

  def confirm!
    transaction do
      update!(status: :confirmed, confirmed_at: Time.current)

      # Create shipment if it doesn't exist yet
      if shipment.nil?
        Shipment.create!(
          order: self,
          status: "pending"
        )
      end
    end
  end

  def cancel!
    transaction do
      update!(status: :cancelled)
      edition.inventory.release_reserved(quantity)
    end
  end

  def update_quantity!(new_quantity)
    return if new_quantity == quantity

    transaction do
      difference = new_quantity - quantity

      if difference > 0
        # Zwiększenie ilości - potrzebna dodatkowa rezerwacja
        raise Inventory::InsufficientStock, "Niewystarczająca ilość pakietów na magazynie" if edition.inventory.available < difference
        edition.inventory.reserve(difference, reference: self)
      elsif difference < 0
        # Zmniejszenie ilości - zwolnienie części rezerwacji
        edition.inventory.release_reserved(-difference)
      end

      self.quantity = new_quantity
      self.total_amount = new_quantity * price_per_unit
      save!
    end
  end

  def can_be_edited_by_leader?
    pending?
  end

  def can_be_cancelled_by_leader?
    pending?
  end

  def has_posters?
    poster_quantity.to_i > 0
  end

  def content_summary
    parts = ["#{quantity} pakietów"]
    parts << "#{poster_quantity} plakatów" if has_posters?
    parts.join(", ")
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
    edition.inventory.reserve(quantity, reference: self)
  end
end
