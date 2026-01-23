require "faraday"
require "openssl"
require "base64"
require "json"

module Apaczka
  class Client
    BASE_URL = "https://www.apaczka.pl/api/v2"

    def initialize
      @app_id = Rails.application.credentials.dig(:apaczka, :app_id)
      @app_secret = Rails.application.credentials.dig(:apaczka, :app_secret)
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

    def build_order_data(order)
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
          receiver: {
            name: order.user.full_name,
            address: order.locker_address,
            city: order.locker_city,
            postal_code: order.locker_post_code,
            phone: order.user.phone,
            email: order.user.email,
            foreign_address_id: order.locker_code,
            is_pickup_point: true
          },
          parcels: [{
            weight: calculate_weight(order.quantity),
            dimensions: package_dimensions
          }],
          comment: "Pakiety EDK - #{order.quantity} szt."
        }
      }
    end

    def post(endpoint, data)
      expires = 30.minutes.from_now.to_i
      signature = generate_signature(endpoint, data.to_json, expires)

      response = Faraday.post("#{BASE_URL}#{endpoint}") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          app_id: @app_id,
          request: data.to_json,
          expires: expires,
          signature: signature
        }.to_json
      end

      JSON.parse(response.body)
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
      string_to_sign = "#{@app_id}#{endpoint}#{data}#{expires}"
      OpenSSL::HMAC.hexdigest("SHA256", @app_secret, string_to_sign)
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
