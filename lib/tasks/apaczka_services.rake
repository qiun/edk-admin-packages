namespace :apaczka do
  desc "Get available service IDs from aPaczka API"
  task get_services: :environment do
    require "faraday"
    require "openssl"
    require "json"

    app_id = (ENV["APACZKA_APP_ID"] || Rails.application.credentials.dig(:apaczka, :app_id)).to_s.strip
    app_secret = (ENV["APACZKA_APP_SECRET"] || Rails.application.credentials.dig(:apaczka, :app_secret)).to_s.strip

    # Get service structure
    endpoint = "/service_structure/"
    route = "service_structure/"
    data = ""
    expires = 30.minutes.from_now.to_i

    string_to_sign = "#{app_id}:#{route}:#{data}:#{expires}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", app_secret, string_to_sign)

    puts "=== Getting aPaczka service structure ==="
    puts "Endpoint: https://www.apaczka.pl/api/v2#{endpoint}"
    puts ""

    response = Faraday.post("https://www.apaczka.pl/api/v2#{endpoint}") do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form({
        app_id: app_id,
        request: data,
        expires: expires,
        signature: signature
      })
    end

    result = JSON.parse(response.body)

    if result["status"] == 200
      puts "✓ Success! Found #{result['response']['services'].length} services"
      puts ""

      # Filter InPost services
      inpost_services = result["response"]["services"].select do |s|
        s["supplier"].to_s.downcase == "inpost"
      end

      puts "=== InPost Services (#{inpost_services.length}) ==="
      inpost_services.each do |service|
        puts ""
        puts "Service ID: #{service['service_id']}"
        puts "Name: #{service['name']}"
        puts "Supplier: #{service['supplier']}"
        puts "door_to_point: #{service['door_to_point']}"
        puts "point_to_point: #{service['point_to_point']}"
        puts "Pickup courier: #{service['pickup_courier']}"
      end

      puts ""
      puts "=== Recommended for Paczkomat delivery ==="
      recommended = inpost_services.select do |s|
        # Looking for services that support delivery to point (paczkomat)
        s["door_to_point"] == 1 || s["point_to_point"] == 1
      end

      recommended.each do |service|
        puts "  - #{service['service_id']}: #{service['name']}"
      end
    else
      puts "Error: #{result['message']}"
      puts "Full response: #{result.inspect}"
    end
  end
end
