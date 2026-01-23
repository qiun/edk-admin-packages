class Notification < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :edition, optional: true

  # Types
  LOW_STOCK = "low_stock"
  OUT_OF_STOCK = "out_of_stock"
  NEW_DONATION = "new_donation"
  PAYMENT_RECEIVED = "payment_received"

  TYPES = [LOW_STOCK, OUT_OF_STOCK, NEW_DONATION, PAYMENT_RECEIVED].freeze

  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_admins, -> { where(user_id: nil).or(where(user: User.where(role: :admin))) }
  scope :stock_alerts, -> { where(notification_type: [LOW_STOCK, OUT_OF_STOCK]) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  # Class methods for creating notifications
  class << self
    def notify_low_stock!(edition:, available:, threshold: 50)
      create!(
        edition: edition,
        notification_type: LOW_STOCK,
        title: "Niski stan magazynowy",
        message: "Pozostało tylko #{available} pakietów na magazynie dla edycji #{edition.name}. Rozważ uzupełnienie zapasów.",
        metadata: { available: available, threshold: threshold }
      )
    end

    def notify_out_of_stock!(edition:)
      create!(
        edition: edition,
        notification_type: OUT_OF_STOCK,
        title: "Brak pakietów na magazynie!",
        message: "Magazyn dla edycji #{edition.name} jest pusty! Zamówienia z upominkami nie mogą być realizowane.",
        metadata: {}
      )
    end
  end
end
