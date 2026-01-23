class Donation < ApplicationRecord
  belongs_to :edition

  has_one :shipment, dependent: :destroy

  enum :payment_status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    refunded: "refunded"
  }, prefix: :payment

  # Basic validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :terms_accepted, acceptance: { message: "Musisz zaakceptować regulamin" }

  # Conditional validations for gift
  validates :locker_code, presence: true, if: :want_gift?
  validates :locker_name, presence: true, if: :want_gift?

  before_create :calculate_amount
  before_create :set_defaults

  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :paid, -> { where(payment_status: :paid) }
  scope :recent, -> { order(created_at: :desc) }

  def full_name
    [ first_name, last_name ].compact.join(" ")
  end

  private

  def calculate_amount
    self.amount = quantity * (edition&.donor_price || 50)
  end

  def set_defaults
    self.payment_status ||= :pending
    self.want_gift ||= false
  end
end
