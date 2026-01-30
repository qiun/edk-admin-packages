# frozen_string_literal: true

module Przelewy24
  # Client for Przelewy24 payment gateway
  # API Documentation: https://developers.przelewy24.pl/
  class Client
    SANDBOX_URL = "https://sandbox.przelewy24.pl"
    PRODUCTION_URL = "https://secure.przelewy24.pl"

    attr_reader :merchant_id, :pos_id, :api_key, :crc_key, :sandbox

    def initialize(merchant_id:, pos_id:, api_key:, crc_key:, sandbox: false)
      @merchant_id = merchant_id.to_i
      @pos_id = pos_id.to_i
      @api_key = api_key
      @crc_key = crc_key
      @sandbox = sandbox
    end

    # Register a new transaction (trnRegister)
    # Returns: { token: "...", redirect_url: "..." }
    def create_transaction(params)
      transaction_data = {
        merchantId: merchant_id,
        posId: pos_id,
        sessionId: params[:session_id],
        amount: (params[:amount].to_f * 100).to_i, # Convert to grosze (cents)
        currency: params[:currency] || "PLN",
        description: params[:description],
        email: params[:email],
        country: params[:country] || "PL",
        language: params[:language] || "pl",
        urlReturn: params[:url_return],
        urlStatus: params[:url_status],
        sign: generate_register_sign(params)
      }

      # Optional fields
      transaction_data[:client] = params[:client] if params[:client]
      transaction_data[:address] = params[:address] if params[:address]
      transaction_data[:zip] = params[:zip] if params[:zip]
      transaction_data[:city] = params[:city] if params[:city]
      transaction_data[:phone] = params[:phone] if params[:phone]

      response = http_post("/api/v1/transaction/register", transaction_data)

      unless response["data"]
        error_details = response.inspect
        Rails.logger.error "Przelewy24 registration failed. Response: #{error_details}"
        raise Error, "Transaction registration failed: #{response['error'] || response['message'] || error_details}"
      end

      token = response.dig("data", "token")
      raise Error, "No token received from Przelewy24" unless token

      {
        token: token,
        redirect_url: "#{base_url}/trnRequest/#{token}"
      }
    end

    # Verify transaction (trnVerify)
    # Called after receiving webhook notification
    def verify_transaction(params)
      verify_data = {
        merchantId: merchant_id,
        posId: pos_id,
        sessionId: params[:session_id],
        amount: params[:amount].to_i,
        currency: params[:currency] || "PLN",
        orderId: params[:order_id].to_i,
        sign: generate_verify_sign(params)
      }

      response = http_post("/api/v1/transaction/verify", verify_data)

      {
        success: response.dig("data", "status") == "success",
        response: response
      }
    end

    # Verify webhook notification signature
    def verify_notification_signature(params)
      expected_sign = generate_notification_sign(params)
      params[:sign] == expected_sign
    end

    private

    def base_url
      sandbox ? SANDBOX_URL : PRODUCTION_URL
    end

    def http_post(endpoint, data)
      uri = URI.parse("#{base_url}#{endpoint}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      # TEMPORARY: Skip SSL verification for both sandbox and production during development
      # TODO: Fix SSL certificate verification for production deployment
      # IMPORTANT: In production deployment, always verify SSL certificates!
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request.basic_auth(pos_id.to_s, api_key)
      request.body = data.to_json

      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      raise Error, "HTTP request failed: #{e.message}"
    end

    # Generate CRC signature for transaction registration
    # Format: {"sessionId":"{SessionId}","merchantId":{MerchantId},"amount":{Amount},"currency":"{Currency}","crc":{CRC}}
    def generate_register_sign(params)
      amount = (params[:amount].to_f * 100).to_i
      currency = params[:currency] || "PLN"
      session_id = params[:session_id]

      sign_data = {
        "sessionId" => session_id,
        "merchantId" => merchant_id,
        "amount" => amount,
        "currency" => currency,
        "crc" => crc_key
      }

      json_string = JSON.generate(sign_data)
      Digest::SHA384.hexdigest(json_string)
    end

    # Generate CRC signature for transaction verification
    # Format: {"sessionId":"{SessionId}","orderId":{OrderId},"amount":{Amount},"currency":"{Currency}","crc":{CRC}}
    def generate_verify_sign(params)
      sign_data = {
        "sessionId" => params[:session_id],
        "orderId" => params[:order_id].to_i,
        "amount" => params[:amount].to_i,
        "currency" => params[:currency] || "PLN",
        "crc" => crc_key
      }

      json_string = JSON.generate(sign_data)
      Digest::SHA384.hexdigest(json_string)
    end

    # Generate CRC signature for webhook notification verification
    # Format: {"sessionId":"{SessionId}","orderId":{OrderId},"amount":{Amount}","currency":"{Currency}","crc":{CRC}}
    # IMPORTANT: Must use JSON.generate without escaping slashes/unicode (like PHP JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
    def generate_notification_sign(params)
      # Convert to hash with symbol keys to ensure consistent access
      params_hash = params.respond_to?(:to_h) ? params.to_h.symbolize_keys : params

      sign_data = {
        "sessionId" => params_hash[:sessionId],
        "orderId" => params_hash[:orderId].to_i,
        "amount" => params_hash[:amount].to_i,
        "currency" => params_hash[:currency] || "PLN",
        "crc" => crc_key
      }

      # Use JSON.generate to avoid escaping slashes (equivalent to PHP JSON_UNESCAPED_SLASHES)
      json_string = JSON.generate(sign_data)

      Rails.logger.info "Przelewy24 signature JSON: #{json_string}"
      generated_sign = Digest::SHA384.hexdigest(json_string)
      Rails.logger.info "Przelewy24 generated signature: #{generated_sign}"

      generated_sign
    end

    class Error < StandardError; end
  end
end
