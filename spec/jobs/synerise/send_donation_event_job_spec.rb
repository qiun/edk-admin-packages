# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synerise::SendDonationEventJob do
  let(:edition) { create(:edition) }
  let(:donation) { create(:donation, :paid, edition: edition) }

  it "calls SendDonationEvent service" do
    service = instance_double(Synerise::SendDonationEvent, call: nil)
    allow(Synerise::SendDonationEvent).to receive(:new).with(donation).and_return(service)

    described_class.perform_now(donation)

    expect(service).to have_received(:call)
  end
end
