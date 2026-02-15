# frozen_string_literal: true

module Synerise
  class SendDonationEventJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(donation)
      Synerise::SendDonationEvent.new(donation).call
    end
  end
end
