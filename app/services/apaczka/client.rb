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
      order_data = build_order_data(order)
      # Wrap in 'order' key as required by API
      data = { order: order_data }
      response = post("/order_send/", data)

      if response["status"] == 200
        # Response structure: response["response"]["order"]["id"]
        order_data = response["response"]["order"]
        {
          success: true,
          order_id: order_data["id"],
          waybill_number: order_data["waybill_number"],
          tracking_url: order_data["tracking_url"]
        }
      else
        { success: false, error: response["message"] }
      end
    end

    def get_waybill(order_id)
  # aPaczka API v2 uses POST for all endpoints, not GET
  # Request parameter should be empty array for waybill retrieval
  response = post("/waybill/#{order_id}/", {})

  if response["status"] == 200
    Base64.decode64(response["response"]["waybill"])
  else
    nil
  end
end

    def get_order_status(order_id)
  # aPaczka API v2 uses POST for all endpoints, not GET
  response = post("/order/#{order_id}/", {})

  if response["status"] == 200
    response["response"]["status"]
  else
    nil
  end
end

    def cancel_order(order_id)
      response = post("/cancel_order/#{order_id}/", {})

      if response["status"] == 200
        { success: true }
      else
        { success: false, error: response["message"] || "Nieznany błąd" }
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
          phone: format_phone(source.phone),
          email: source.email
        }
      else
        # Order object
        {
          name: source.user.full_name,
          phone: format_phone(source.user.phone),
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

      dims = package_dimensions(source)
      sender = sender_config(source)

      # Structure according to aPaczka API v2 documentation
      {
        service_id: 41,  # InPost Paczkomat (door_to_point + point_to_point)
        address: {
          sender: {
            country_code: "PL",
            name: sender[:name],
            line1: sender[:street],
            postal_code: sender[:post_code],
            city: sender[:city],
            email: sender[:email],
            phone: format_phone(sender[:phone])
          },
          receiver: {
            country_code: "PL",
            name: receiver_data[:name],
            line1: locker_info[:address],
            postal_code: locker_info[:postal_code],
            city: locker_info[:city],
            email: receiver_data[:email],
            phone: receiver_data[:phone],
            foreign_address_id: source.locker_code
          }
        },
        pickup: {
          type: "SELF",
          date: Date.today.strftime("%Y-%m-%d"),
          hours_from: "09:00",
          hours_to: "17:00"
        },
        shipment: [ {
          weight: calculate_weight(source.quantity, source),
          dimension1: dims[:length],
          dimension2: dims[:width],
          dimension3: dims[:height]
        } ],
        content: "Pakiety EDK - #{source.quantity} szt."
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

    def generate_signature(endpoint, data, expires)
      # Per aPaczka API documentation: "app_id:route:data:expires"
      # IMPORTANT: Remove only leading slash, keep trailing slash
      # Example: "/order_send/" becomes "order_send/"
      route = endpoint.to_s.gsub(/^\//, "")

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

    def sender_config(source)
      if source.is_a?(Order)
        Rails.application.credentials.dig(:apaczka, :order_sender) || default_order_sender_config
      else
        Rails.application.credentials.dig(:apaczka, :donation_sender) || default_donation_sender_config
      end
    end

    def default_order_sender_config
      {
        name: "Magazyn EDK - Rafał Wojtkiewicz",
        street: "ul. Konarskiego 8",
        city: "Świebodzin",
        post_code: "66-200",
        phone: "602736554",
        email: "pakiety@edk.org.pl"
      }
    end

    def default_donation_sender_config
      {
        name: "Sklep EDK - Rafał Wojtkiewicz",
        street: "ul. Sobieskiego 19",
        city: "Świebodzin",
        post_code: "66-200",
        phone: "602736554",
        email: "pakiety@edk.org.pl"
      }
    end

    def calculate_weight(quantity, source)
      if source.is_a?(Order)
        # Paczki do liderów zawsze pakowane do max 25 kg
        # aPaczka/InPost limit: waga < 25 kg (nie może równać się 25)
        weight = ((quantity * 0.3) + 2.0).round(2)
        [ weight, 24.9 ].min
      else
        # Cegiełki - małe paczuszki
        weight = ((quantity * 0.15) + 0.5).round(2)
        [ weight, 24.9 ].min
      end
    end

    def package_dimensions(source)
      if source.is_a?(Order)
        # Dla liderów okręgowych - wymiary z edition
        edition = source.edition
        {
          length: (edition&.order_package_length || 41).to_i,
          width: (edition&.order_package_width || 38).to_i,
          height: (edition&.order_package_height || 64).to_i
        }
      else
        # Dla cegiełek - wymiary z edition
        edition = source.edition
        {
          length: (edition&.donation_package_length || 19).to_i,
          width: (edition&.donation_package_width || 38).to_i,
          height: (edition&.donation_package_height || 64).to_i
        }
      end
    end

    def format_phone(phone)
      # aPaczka expects phone in format: +48XXXXXXXXX
      digits = phone.to_s.gsub(/\D/, "")
      digits = digits.sub(/^48/, "") if digits.start_with?("48")
      "+48#{digits[-9..-1]}"
    end
  end
end
