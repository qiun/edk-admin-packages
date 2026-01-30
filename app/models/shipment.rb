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
  scope :for_orders, -> { where.not(order_id: nil) }
  scope :for_donations, -> { where.not(donation_id: nil) }

  # Enqueue aPaczka job after record is committed to database
  # This prevents race condition where job runs before transaction commits
  after_commit :enqueue_apaczka_job, on: :create

  def source
    order || donation
  end

  private

  def must_have_order_or_donation
    if order.blank? && donation.blank?
      errors.add(:base, "Shipment must belong to an order or donation")
    end
  end

  def enqueue_apaczka_job
    # Only create shipment in aPaczka for new pending shipments
    return unless status == "pending"
    return unless apaczka_order_id.blank?

    Apaczka::CreateShipmentJob.perform_later(self)
    Rails.logger.info "Enqueued aPaczka job for shipment ##{id}"
  end
end
