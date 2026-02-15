# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synerise::Client do
  let(:client) { described_class.new }

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

  describe "#enabled?" do
    it "returns true when SYNERISE_ENABLED is true" do
      expect(client).to be_enabled
    end

    it "returns false when SYNERISE_ENABLED is false" do
      ENV["SYNERISE_ENABLED"] = "false"
      expect(described_class.new).not_to be_enabled
    end
  end

  describe "#create_profile" do
    let(:profile_data) { { email: "jan@example.com", first_name: "Jan", last_name: "Kowalski", phone: "123456789" } }

    it "sends POST to /v4/clients" do
      stub = stub_request(:post, "https://api.synerise.com/v4/clients")
        .with(
          body: { email: "jan@example.com", firstName: "Jan", lastName: "Kowalski", phone: "123456789", agreements: { email: true } }.to_json,
          headers: { "Content-Type" => "application/json", "Api-Version" => "4.4" }
        )
        .to_return(status: 200, body: "")

      expect(client.create_profile(profile_data)).to be true
      expect(stub).to have_been_requested
    end

    it "returns false when disabled" do
      ENV["SYNERISE_ENABLED"] = "false"
      expect(described_class.new.create_profile(profile_data)).to be false
    end
  end

  describe "#fetch_profile" do
    it "returns profile hash when found" do
      stub_request(:get, "https://api.synerise.com/v4/clients/by-email/jan%40example.com")
        .to_return(status: 200, body: { email: "jan@example.com", firstName: "Jan" }.to_json)

      result = client.fetch_profile("jan@example.com")
      expect(result["email"]).to eq("jan@example.com")
    end

    it "returns nil when not found" do
      stub_request(:get, "https://api.synerise.com/v4/clients/by-email/unknown%40example.com")
        .to_return(status: 404, body: "")

      expect(client.fetch_profile("unknown@example.com")).to be_nil
    end
  end

  describe "#create_event" do
    let(:event_data) do
      {
        action: "wplata.fio",
        label: "wplata.fio",
        client: { email: "jan@example.com" },
        params: { amount: "100", currency: "PLN" }
      }
    end

    it "sends POST to /v4/events/custom" do
      stub = stub_request(:post, "https://api.synerise.com/v4/events/custom")
        .to_return(status: 200, body: "")

      expect(client.create_event(event_data)).to be true
      expect(stub).to have_been_requested
    end
  end
end
