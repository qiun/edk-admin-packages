class RegionalPayment < ApplicationRecord
  belongs_to :region
  belongs_to :edition
  belongs_to :recorded_by, class_name: "User"

  has_one_attached :confirmation

  validates :amount, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validate :confirmation_file_type, if: -> { confirmation.attached? }

  scope :for_region, ->(region) { where(region: region) }
  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :recent, -> { order(payment_date: :desc, created_at: :desc) }

  private

  def confirmation_file_type
    return unless confirmation.attached?

    acceptable_types = [ "application/pdf", "image/jpeg", "image/jpg", "image/png" ]
    unless acceptable_types.include?(confirmation.content_type)
      errors.add(:confirmation, "musi być plikiem PDF, JPG lub PNG")
    end
  end
end
