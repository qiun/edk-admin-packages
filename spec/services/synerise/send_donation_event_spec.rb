# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synerise::SendDonationEvent do
  let(:edition) { create(:edition) }
  let(:donation) do
    create(:donation, :paid,
      edition: edition,
      email: "jan@example.com",
      first_name: "Jan",
      last_name: "Kowalski",
      phone: "123456789",
      amount: 80.0
    )
  end

  before do
    ENV["SYNERISE_ENABLED"] = "true"
    ENV["SYNERISE_WORKSPACE_GUID"] = "test-guid"
    ENV["SYNERISE_API_KEY"] = "test-key"
  end

  after do
    ENV.delete("SYNERISE_ENABLED")
    ENV.delete("SYNERISE_WORKSPACE_GUID")
    ENV.delete("SYNERISE_API_KEY")
  end

  describe "#call" do
    it "creates profile and sends event when profile does not exist" do
      fetch_stub = stub_request(:get, "https://api.synerise.com/v4/clients/by-email/jan%40example.com")
        .to_return(status: 404, body: "")

      create_stub = stub_request(:post, "https://api.synerise.com/v4/clients")
        .to_return(status: 200, body: "")

      event_stub = stub_request(:post, "https://api.synerise.com/v4/events/custom")
        .to_return(status: 200, body: "")

      described_class.new(donation).call

      expect(fetch_stub).to have_been_requested
      expect(create_stub).to have_been_requested
      expect(event_stub).to have_been_requested
    end

    it "skips profile creation when profile already exists" do
      stub_request(:get, "https://api.synerise.com/v4/clients/by-email/jan%40example.com")
        .to_return(status: 200, body: { email: "jan@example.com" }.to_json)

      event_stub = stub_request(:post, "https://api.synerise.com/v4/events/custom")
        .to_return(status: 200, body: "")

      described_class.new(donation).call

      expect(event_stub).to have_been_requested
    end

    it "does nothing when Synerise is disabled" do
      ENV["SYNERISE_ENABLED"] = "false"

      described_class.new(donation).call

      expect(WebMock).not_to have_requested(:any, /synerise/)
    end

    it "does nothing when donation is not paid" do
      donation.update_column(:payment_status, "pending")

      described_class.new(donation.reload).call

      expect(WebMock).not_to have_requested(:any, /synerise/)
    end
  end
end
