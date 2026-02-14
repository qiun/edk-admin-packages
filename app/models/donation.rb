class Donation < ApplicationRecord
  belongs_to :edition

  has_one :shipment, dependent: :destroy

  enum :payment_status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    refunded: "refunded",
    abandoned: "abandoned"
  }, prefix: :payment

  # Basic validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: {
    with: /\A\d{9}\z/,
    message: "musi składać się z 9 cyfr"
  }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :terms_accepted, acceptance: { message: "Musisz zaakceptować regulamin" }

  # Conditional validations for gift
  validates :locker_code, presence: true, if: :want_gift?
  validates :locker_name, presence: true, if: :want_gift?

  before_validation :normalize_phone
  before_create :calculate_amount
  before_create :set_defaults

  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :paid, -> { where(payment_status: :paid) }
  scope :recent, -> { order(created_at: :desc) }

  def full_name
    [ first_name, last_name ].compact.join(" ")
  end

  private

  def normalize_phone
    return if phone.blank?

    # Strip all non-digit characters
    digits_only = phone.gsub(/\D/, "")

    # Remove +48 prefix if present
    digits_only = digits_only.sub(/^48/, "") if digits_only.start_with?("48") && digits_only.length > 9

    # Keep only last 9 digits if longer (handles cases like "58838998278" -> "838998278")
    self.phone = digits_only[-9..-1] if digits_only.length >= 9
  end

  def calculate_amount
    brick_price = edition&.donor_brick_price || 30
    shipping_cost = edition&.donor_shipping_cost || 20
    self.amount = shipping_cost + (quantity * brick_price)
  end

  def set_defaults
    self.payment_status ||= :pending
    self.want_gift ||= false
  end
end
