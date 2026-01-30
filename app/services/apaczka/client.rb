require "faraday"
require "openssl"
require "base64"
require "json"
require "digest"

module Apaczka
  class Client
    BASE_URL = "https://www.apaczka.pl/api/v2"

    def initialize
      @app_id = (ENV["APACZKA_APP_ID"] || Rails.application.credentials.dig(:apaczka, :app_id)).to_s.strip
      @app_secret = (ENV["APACZKA_APP_SECRET"] || Rails.application.credentials.dig(:apaczka, :app_secret)).to_s.strip
      @sandbox = ENV["APACZKA_SANDBOX"] == "true" || Rails.application.credentials.dig(:apaczka, :sandbox)

      Rails.logger.info "aPaczka Client initialized with app_id: #{@app_id}, sandbox: #{@sandbox}"
      Rails.logger.info "aPaczka app_secret length: #{@app_secret.length}, first 8 chars: #{@app_secret[0..7]}, last 4 chars: #{@app_secret[-4..-1]}"
      Rails.logger.warn "aPaczka app_secret is missing!" if @app_secret.blank?
      Rails.logger.warn "aPaczka app_id is missing!" if @app_id.blank?
    end

    def create_shipment(order)
      data = build_order_data(order)
      response = post("/order_send/", data)

      if response["status"] == 200
        {
          success: true,
          order_id: response["response"]["id"],
          waybill_number: response["response"]["waybill_number"],
          tracking_url: response["response"]["tracking_url"]
        }
      else
        { success: false, error: response["message"] }
      end
    end

    def get_waybill(order_id)
      response = get("/waybill/#{order_id}/")

      if response["status"] == 200
        Base64.decode64(response["response"]["waybill"])
      else
        nil
      end
    end

    def get_order_status(order_id)
      response = get("/order/#{order_id}/")

      if response["status"] == 200
        response["response"]["status"]
      else
        nil
      end
    end

    private


    def parse_locker_info(locker_name, locker_code)
      # Format: "CODE - Address, POSTAL_CODE City"
      # Example: "OSC01M - Rataja 9, 88-220 Osięciny"
      return { address: "", city: "", postal_code: "" } if locker_name.blank?

      # Remove code prefix if present
      name_without_code = locker_name.sub(/^#{Regexp.escape(locker_code)}\s*-\s*/, "")

      # Split by comma to separate address from "postal_code city"
      parts = name_without_code.split(",").map(&:strip)
      return { address: "", city: "", postal_code: "" } if parts.empty?

      address = parts[0] || ""

      # Parse "88-220 Osięciny" into postal_code and city
      postal_and_city = parts[1]&.strip || ""
      if postal_and_city =~ /^(\d{2}-\d{3})\s+(.+)$/
        postal_code = $1
        city = $2
      else
        postal_code = ""
        city = postal_and_city
      end

      { address: address, city: city, postal_code: postal_code }
    end

    def build_order_data(source)
      # Support both Order and Donation objects
      receiver_data = if source.is_a?(Donation)
        {
          name: source.full_name,
          phone: source.phone,
          email: source.email
        }
      else
        # Order object
        {
          name: source.user.full_name,
          phone: source.user.phone,
          email: source.user.email
        }
      end

      # Parse locker info if fields are empty
      locker_info = if source.locker_address.blank? && source.locker_name.present?
        parse_locker_info(source.locker_name, source.locker_code)
      else
        {
          address: source.locker_address,
          city: source.locker_city,
          postal_code: source.locker_post_code
        }
      end

      Rails.logger.info "aPaczka locker info: #{locker_info.inspect}"

      {
        order: {
          service_id: "INPOST_COURIER_POINT",
          pickup: {
            type: "SELF",
            sender_name: sender_config[:name],
            sender_address: sender_config[:street],
            sender_city: sender_config[:city],
            sender_postal_code: sender_config[:post_code],
            sender_phone: sender_config[:phone],
            sender_email: sender_config[:email]
          },
          receiver: receiver_data.merge(
            address: locker_info[:address],
            city: locker_info[:city],
            postal_code: locker_info[:postal_code],
            foreign_address_id: source.locker_code,
            is_pickup_point: true
          ),
          parcels: [ {
            weight: calculate_weight(source.quantity),
            dimensions: package_dimensions
          } ],
          comment: "Pakiety EDK - #{source.quantity} szt."
        }
      }
    end

    def post(endpoint, data)
      expires = 30.minutes.from_now.to_i
      request_json = data.to_json
      signature = generate_signature(endpoint, request_json, expires)

      form_params = {
        app_id: @app_id,
        request: request_json,
        expires: expires,
        signature: signature
      }

      Rails.logger.info "=== aPaczka API POST ==="
      Rails.logger.info "Endpoint: #{BASE_URL}#{endpoint}"
      Rails.logger.info "Form params: app_id=#{form_params[:app_id]}, expires=#{form_params[:expires]}, signature=#{form_params[:signature]}"
      Rails.logger.info "Request JSON length: #{request_json.length} bytes"

      response = Faraday.post("#{BASE_URL}#{endpoint}") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(form_params)
      end

      Rails.logger.info "Response status: #{response.status}"
      Rails.logger.info "Response body: #{response.body}"

      response_data = JSON.parse(response.body)
      Rails.logger.info "Parsed status: #{response_data['status']}"
      Rails.logger.info "=== End API POST ==="

      response_data
    end

    def get(endpoint)
      expires = 30.minutes.from_now.to_i
      signature = generate_signature(endpoint, "", expires)

      response = Faraday.get("#{BASE_URL}#{endpoint}") do |req|
        req.params = {
          app_id: @app_id,
          expires: expires,
          signature: signature
        }
      end

      JSON.parse(response.body)
    end

    def generate_signature(endpoint, data, expires)
      # Per aPaczka API documentation: "app_id:route:data:expires"
      # IMPORTANT: route must NOT have leading/trailing slashes
      # Example: "order_send" not "/order_send/"
      route = endpoint.to_s.gsub(/^\/|\/$/,  "")

      # Log each component separately for detailed analysis
      Rails.logger.info "=== Signature Component Analysis ==="
      Rails.logger.info "App ID: '#{@app_id}' (#{@app_id.bytesize} bytes, encoding: #{@app_id.encoding})"
      Rails.logger.info "Route: '#{route}' (#{route.bytesize} bytes)"
      Rails.logger.info "Data: '#{data[0..100]}...' (#{data.bytesize} bytes, encoding: #{data.encoding})"
      Rails.logger.info "Expires: '#{expires}' (class: #{expires.class})"

      # Build string to sign
      string_to_sign = "#{@app_id}:#{route}:#{data}:#{expires}"

      Rails.logger.info "String to sign: #{string_to_sign.bytesize} bytes"
      Rails.logger.info "String encoding: #{string_to_sign.encoding}"
      Rails.logger.info "First 200 bytes (hex): #{string_to_sign[0..199].bytes.map { |b| b.to_s(16).rjust(2, '0') }.join(' ')}"

      # Log secret hash for verification (never log the actual secret!)
      Rails.logger.info "App secret MD5 (for verification): #{Digest::MD5.hexdigest(@app_secret)}"

      signature = OpenSSL::HMAC.hexdigest("SHA256", @app_secret, string_to_sign)

      Rails.logger.info "Generated signature: #{signature}"
      Rails.logger.info "=== End Component Analysis ==="

      signature
    end

    def sender_config
      Rails.application.credentials.dig(:apaczka, :sender) || default_sender_config
    end

    def default_sender_config
      {
        name: "EDK Koordynacja",
        street: "ul. Przykładowa 1",
        city: "Warszawa",
        post_code: "00-001",
        phone: "123456789",
        email: "kontakt@edk.pl"
      }
    end

    def calculate_weight(quantity)
      # 1 pakiet ~ 150g, karton ~500g
      ((quantity * 0.15) + 0.5).round(2)
    end

    def package_dimensions
      # Karton na 150 pakietów: 40x30x25 cm
      { length: 40, width: 30, height: 25 }
    end
  end
end
