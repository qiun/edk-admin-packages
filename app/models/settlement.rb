class Settlement < ApplicationRecord
  belongs_to :user
  belongs_to :edition

  enum :status, {
    pending: "pending",
    calculated: "calculated",
    paid: "paid",
    closed: "closed"
  }

  validates :user_id, uniqueness: { scope: :edition_id }
  validates :total_sent, :total_returned, :total_sold,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :for_edition, ->(edition) { where(edition: edition) }

  def balance
    (amount_due || 0) - (amount_paid || 0)
  end

  def fully_paid?
    balance <= 0
  end

  def recalculate!
    orders = user.orders.for_edition(edition).where(status: [ :shipped, :delivered ])
    returns = user.returns.where(edition: edition, status: :received)
    reports = user.sales_reports.where(edition: edition)

    self.total_sent = orders.sum(:quantity)
    self.total_returned = returns.sum(:quantity)
    self.total_sold = reports.sum(:quantity_sold)
    self.price_per_unit = user.effective_price_for(edition)
    self.amount_due = total_sold * price_per_unit
    self.status = amount_due <= amount_paid ? :paid : :pending

    save!
  end
end
