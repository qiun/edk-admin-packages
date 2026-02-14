class AbandonExpiredDonationsJob < ApplicationJob
  queue_as :low

  EXPIRY_HOURS = 24

  def perform
    expired = Donation.where(payment_status: "pending")
                      .where("created_at < ?", EXPIRY_HOURS.hours.ago)

    count = expired.count
    return if count.zero?

    expired.find_each do |donation|
      donation.update!(payment_status: :abandoned)
    end

    Rails.logger.info "Abandoned #{count} expired donations"
  end
end
