namespace :apaczka do
  desc "Verify aPaczka credentials format"
  task verify_credentials: :environment do
    app_id = ENV["APACZKA_APP_ID"] || Rails.application.credentials.dig(:apaczka, :app_id)
    app_secret = ENV["APACZKA_APP_SECRET"] || Rails.application.credentials.dig(:apaczka, :app_secret)

    puts "=== Credential Analysis ==="
    puts "App ID present: #{app_id.present?}"
    puts "App ID length: #{app_id.to_s.length} chars"
    puts "App ID format: #{app_id}"
    puts "App ID encoding: #{app_id.to_s.encoding}"
    puts "App ID bytes: #{app_id.to_s.bytes.inspect}"
    puts ""
    puts "App Secret present: #{app_secret.present?}"
    puts "App Secret length: #{app_secret.to_s.length} chars"
    puts "App Secret encoding: #{app_secret.to_s.encoding}"
    puts "App Secret starts with: #{app_secret.to_s[0..7]}"
    puts "App Secret ends with: #{app_secret.to_s[-8..-1]}"
    puts "App Secret MD5: #{Digest::MD5.hexdigest(app_secret.to_s)}"
    puts "App Secret bytes (first 10): #{app_secret.to_s.bytes[0..9].inspect}"
    puts "App Secret bytes (last 10): #{app_secret.to_s.bytes[-10..-1].inspect}"
    puts ""
    puts "=== Checking for invisible characters ==="

    # Check for BOM
    if app_secret.to_s.bytes.first(3) == [ 0xEF, 0xBB, 0xBF ]
      puts "⚠️  WARNING: App Secret starts with UTF-8 BOM!"
    end

    # Check for non-printable characters
    non_printable = app_secret.to_s.chars.select { |c| c.ord < 32 || c.ord > 126 }
    if non_printable.any?
      puts "⚠️  WARNING: App Secret contains non-printable characters:"
      non_printable.each do |c|
        puts "  - Character code: #{c.ord} (0x#{c.ord.to_s(16)})"
      end
    else
      puts "✓ No non-printable characters found"
    end

    # Check for whitespace
    if app_id.to_s != app_id.to_s.strip
      puts "⚠️  WARNING: App ID has leading/trailing whitespace"
    end
    if app_secret.to_s != app_secret.to_s.strip
      puts "⚠️  WARNING: App Secret has leading/trailing whitespace"
    end
  end
end
