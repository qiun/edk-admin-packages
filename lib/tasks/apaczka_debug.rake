namespace :apaczka do
  desc "Debug signature generation with multiple formats"
  task debug_signature: :environment do
    client = Apaczka::Client.new

    # Get test donation
    donation = Donation.where(payment_status: :paid).last
    unless donation
      puts "No paid donation found for testing"
      exit 1
    end

    puts "Testing with Donation ##{donation.id}"

    # Build order data
    data = client.send(:build_order_data, donation)
    request_json = data.to_json

    # Get credentials
    app_id = client.instance_variable_get(:@app_id)
    app_secret = client.instance_variable_get(:@app_secret)
    expires = 30.minutes.from_now.to_i

    # Test variations
    tests = [
      {
        name: "Current implementation (order_send)",
        route: "order_send",
        data: request_json,
        expires: expires
      },
      {
        name: "With leading slash (/order_send)",
        route: "/order_send",
        data: request_json,
        expires: expires
      },
      {
        name: "With trailing slash (order_send/)",
        route: "order_send/",
        data: request_json,
        expires: expires
      },
      {
        name: "With both slashes (/order_send/)",
        route: "/order_send/",
        data: request_json,
        expires: expires
      },
      {
        name: "Expires as string",
        route: "order_send",
        data: request_json,
        expires: expires.to_s
      },
      {
        name: "URL-encoded data",
        route: "order_send",
        data: CGI.escape(request_json),
        expires: expires
      }
    ]

    tests.each_with_index do |test, index|
      puts "\n=== Test #{index + 1}: #{test[:name]} ==="

      string_to_sign = "#{app_id}:#{test[:route]}:#{test[:data]}:#{test[:expires]}"
      signature = OpenSSL::HMAC.hexdigest("SHA256", app_secret, string_to_sign)

      puts "Signature: #{signature}"

      # Make API request
      begin
        response = Faraday.post("https://www.apaczka.pl/api/v2/order_send/") do |req|
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form({
            app_id: app_id,
            request: request_json,
            expires: expires,
            signature: signature
          })
        end

        result = JSON.parse(response.body)
        puts "Status: #{result['status']}"
        puts "Message: #{result['message']}"

        if result["status"] == 200
          puts "\n✓✓✓ SUCCESS! This format works! ✓✓✓"
          puts "Use this format: #{test[:name]}"
          break
        end
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end
end
