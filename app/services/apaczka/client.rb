require "faraday"
require "openssl"
require "base64"
require "json"

module Apaczka
  class Client
    BASE_URL = "https://www.apaczka.pl/api/v2"

    def initialize
      @app_id = ENV['APACZKA_APP_ID'] || Rails.application.credentials.dig(:apaczka, :app_id)
      @app_secret = ENV['APACZKA_APP_SECRET'] || Rails.application.credentials.dig(:apaczka, :app_secret)
      @sandbox = ENV['APACZKA_SANDBOX'] == 'true' || Rails.application.credentials.dig(:apaczka, :sandbox)
      
      Rails.logger.info "aPaczka Client initialized with app_id: #{@app_id}, sandbox: #{@sandbox}"
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
            address: source.locker_address,
            city: source.locker_city,
            postal_code: source.locker_post_code,
            foreign_address_id: source.locker_code,
            is_pickup_point: true
          ),
          parcels: [{
            weight: calculate_weight(source.quantity),
            dimensions: package_dimensions
          }],
          comment: "Pakiety EDK - #{source.quantity} szt."
        }
      }
    end

    def post(endpoint, data)
      expires = 30.minutes.from_now.to_i
      request_json = data.to_json
      signature = generate_signature(endpoint, request_json, expires)

      Rails.logger.info "aPaczka API POST to #{endpoint}"
      Rails.logger.info "aPaczka app_id: #{@app_id}"
      Rails.logger.info "aPaczka expires: #{expires}"
      Rails.logger.info "aPaczka request data: #{request_json[0..500]}"
      Rails.logger.info "aPaczka signature: #{signature}"

      response = Faraday.post("#{BASE_URL}#{endpoint}") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form({
          app_id: @app_id,
          request: request_json,
          expires: expires,
          signature: signature
        })
      end

      response_data = JSON.parse(response.body)
      Rails.logger.info "aPaczka API response status: #{response_data['status']}"
      Rails.logger.info "aPaczka API response: #{response.body[0..500]}"
      
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
      string_to_sign = "#{@app_id}:#{endpoint}:#{data}:#{expires}"
      Rails.logger.info "aPaczka string_to_sign (first 200 chars): #{string_to_sign[0..200]}"
      Rails.logger.info "aPaczka app_secret present: #{@app_secret.present?}"
      signature = OpenSSL::HMAC.hexdigest("SHA256", @app_secret, string_to_sign)
      Rails.logger.info "aPaczka generated signature: #{signature}"
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
