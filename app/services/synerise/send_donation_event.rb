# frozen_string_literal: true

module Synerise
  class SendDonationEvent
    def initialize(donation)
      @donation = donation
      @client = Synerise::Client.new
    end

    def call
      return unless @client.enabled?
      return unless @donation.payment_paid?

      ensure_profile_exists
      send_event
    end

    private

    def ensure_profile_exists
      existing = @client.fetch_profile(@donation.email)
      return if existing

      @client.create_profile(
        email: @donation.email,
        first_name: @donation.first_name,
        last_name: @donation.last_name,
        phone: @donation.phone
      )
    end

    def send_event
      @client.create_event(
        action: "wplata.fio",
        label: "wplata.fio",
        client: { email: @donation.email },
        time: @donation.created_at.iso8601,
        params: {
          amount: @donation.amount.to_i.to_s,
          currency: "PLN",
          eventType: "DONATION",
          email: @donation.email,
          eventCreateTime: @donation.created_at.to_s,
          eventDate: @donation.created_at.strftime("%Y-%m-%d"),
          campaign: "",
          recordId: @donation.id.to_s
        }
      )
    end
  end
end
