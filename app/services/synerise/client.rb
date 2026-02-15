# frozen_string_literal: true

module Synerise
  class Client
    BASE_URL = "https://api.synerise.com"
    API_VERSION = "4.4"

    class Error < StandardError; end

    def initialize
      @enabled = ENV.fetch("SYNERISE_ENABLED", "false") == "true"
      @api_url = ENV.fetch("SYNERISE_API_URL", BASE_URL)
      @workspace_guid = ENV.fetch("SYNERISE_WORKSPACE_GUID", "")
      @api_key = ENV.fetch("SYNERISE_API_KEY", "")
    end

    def enabled?
      @enabled
    end

    def create_profile(profile_data)
      return false unless enabled?

      body = {
        email: profile_data[:email],
        firstName: profile_data[:first_name],
        lastName: profile_data[:last_name],
        phone: profile_data[:phone],
        agreements: { email: true }
      }.compact

      response = connection.post("/v4/clients", body.to_json)

      if response.success?
        Rails.logger.info "Synerise: Created profile for #{profile_data[:email]}"
        true
      else
        Rails.logger.error "Synerise: Failed to create profile for #{profile_data[:email]} — #{response.status}: #{response.body}"
        false
      end
    end

    def fetch_profile(email)
      return nil unless enabled?

      response = connection.get("/v4/clients/by-email/#{CGI.escape(email)}")

      if response.success?
        JSON.parse(response.body)
      elsif response.status == 404
        nil
      else
        Rails.logger.error "Synerise: Failed to fetch profile for #{email} — #{response.status}: #{response.body}"
        nil
      end
    end

    def create_event(event_data)
      return false unless enabled?

      response = connection.post("/v4/events/custom", event_data.to_json)

      if response.success?
        Rails.logger.info "Synerise: Created event #{event_data[:action]} for #{event_data.dig(:client, :email)}"
        true
      else
        Rails.logger.error "Synerise: Failed to create event — #{response.status}: #{response.body}"
        false
      end
    end

    def create_events_batch(events)
      return false unless enabled?

      response = connection.post("/v4/events/batch", events.to_json)

      if response.success?
        Rails.logger.info "Synerise: Sent batch of #{events.size} events"
        true
      else
        Rails.logger.error "Synerise: Failed to send batch events — #{response.status}: #{response.body}"
        false
      end
    end

    private

    def connection
      @connection ||= Faraday.new(url: @api_url) do |f|
        f.request :authorization, :basic, @workspace_guid, @api_key
        f.headers["Content-Type"] = "application/json"
        f.headers["Api-Version"] = API_VERSION
        f.adapter Faraday.default_adapter
      end
    end
  end
end
