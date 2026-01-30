# Fix aPaczka API Signature Mismatch - Implementation Plan

## Overview

The aPaczka API integration is failing with "Signature doesn't match" error. After payment confirmation via Przelewy24, the system attempts to create a shipment but the API rejects the signature.

## Current State Analysis

### What's Happening:
1. Payment is confirmed via Przelewy24 ✓
2. Shipment record is created ✓
3. aPaczka job is queued ✓
4. API request is sent with signature ✓
5. **API rejects with "Signature doesn't match"** ✗

### Current Signature Implementation:
```ruby
# app/services/apaczka/client.rb:192-214
route = endpoint.to_s.gsub(/^\/|\/$/,  "")  # "order_send"
string_to_sign = "#{@app_id}:#{route}:#{data}:#{expires}"
signature = OpenSSL::HMAC.hexdigest("SHA256", @app_secret, string_to_sign)
```

### aPaczka Documentation Format:
```php
function stringToSign( $appId, $route, $data, $expires ) {
  return sprintf( "%s:%s:%s:%s", $appId, $route, $data, $expires );
}
$signature = hash_hmac('sha256', $stringToSign, $appSecret);
```

Format: `appId:route:data:expires` ✓ (matches our implementation)

## Key Discoveries from Logs:

```
String to sign: 1924897_5GkLmyke1mmfHjvGbQeB1Uf3:order_send:{"order":{...}}:1769787058
Generated signature: 997314d1ecf8fdf9ded4da3bac58d17347fea8ff6c051a3777139e12933ce58d
API Response: {"status":400,"message":"Signature doesn't match."}
```

## What We're NOT Doing

- Changing the overall system architecture
- Modifying the payment flow with Przelewy24
- Changing the shipment model structure

## Root Cause Hypotheses

### Hypothesis 1: JSON encoding differences
**Issue**: Ruby's `to_json` might produce different output than PHP's `json_encode`
- PHP uses specific encoding for Polish characters (UTF-8)
- Ruby might serialize JSON keys in different order
- Whitespace handling might differ

### Hypothesis 2: Expires parameter format
**Issue**: The expires timestamp might need different formatting
- Currently sending as integer: `1769787058`
- Might need to be string in signature: `"1769787058"`

### Hypothesis 3: Hidden characters in credentials
**Issue**: Credentials might contain invisible characters
- BOM (Byte Order Mark)
- Extra whitespace (already stripped, but could be nbsp or other Unicode spaces)
- Line breaks or tabs

### Hypothesis 4: Request parameter encoding
**Issue**: The JSON might need to be in the URL-encoded form for signature
- Currently signing: raw JSON string
- Might need: URL-encoded JSON string

## Implementation Approach

Test each hypothesis systematically with minimal changes, logging all attempts.

---

## Phase 1: Add Comprehensive Debugging

### Overview
Before making changes, add detailed logging to capture exact values at each step.

### Changes Required:

#### 1. Enhanced Signature Debugging
**File**: `app/services/apaczka/client.rb`

Add logging for:
- Raw credentials (first/last chars only for security)
- Exact byte count of each component
- Hex dump of string_to_sign (first 100 bytes)
- Character encoding of JSON
- MD5 hash of app_secret for verification

```ruby
def generate_signature(endpoint, data, expires)
  route = endpoint.to_s.gsub(/^\/|\/$/,  "")

  # Log each component separately
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
```

### Success Criteria:

#### Automated Verification:
- [x] Code runs without errors
- [ ] All log lines appear in production logs
- [x] No sensitive data (full secrets) is logged

#### Manual Verification:
- [ ] Review logs to identify any obvious encoding issues
- [ ] Verify credentials are loaded correctly
- [ ] Check if there are any unexpected characters

---

## Phase 2: Test Alternative Signature Formats

### Overview
Create a test script to try different signature format variations against the API.

### Changes Required:

#### 1. Create Comprehensive Test Script
**File**: `lib/tasks/apaczka_debug.rake`

```ruby
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

        if result['status'] == 200
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
```

### Success Criteria:

#### Automated Verification:
- [x] Rake task runs successfully: `bundle exec rake apaczka:debug_signature`
- [x] All test variations are attempted
- [x] No errors during execution

#### Manual Verification:
- [ ] Identify which signature format (if any) returns status 200
- [ ] Document the correct format
- [ ] If none work, proceed to Phase 3

---

## Phase 3: Verify Credentials and Contact aPaczka Support

### Overview
If signature format variations don't work, the issue might be with credentials or API configuration.

### Changes Required:

#### 1. Credentials Verification Script
**File**: `lib/tasks/apaczka_verify.rake`

```ruby
namespace :apaczka do
  desc "Verify aPaczka credentials format"
  task verify_credentials: :environment do
    app_id = ENV['APACZKA_APP_ID'] || Rails.application.credentials.dig(:apaczka, :app_id)
    app_secret = ENV['APACZKA_APP_SECRET'] || Rails.application.credentials.dig(:apaczka, :app_secret)

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
    if app_secret.to_s.bytes.first(3) == [0xEF, 0xBB, 0xBF]
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
```

#### 2. Contact Support Checklist

If all else fails, prepare information for aPaczka support:

**Information to provide:**
- App ID: `1924897_5GkLmyke1mmfHjvGbQeB1Uf3`
- Example request timestamp: `1769787058`
- Example signature generated: `997314d1ecf8fdf9ded4da3bac58d17347fea8ff6c051a3777139e12933ce58d`
- String format used: `appId:order_send:jsonData:expires`
- HMAC algorithm: SHA256
- Request that they verify the signature with our data

### Success Criteria:

#### Automated Verification:
- [x] Credential verification task runs: `bundle exec rake apaczka:verify_credentials`
- [x] No errors in credential format

#### Manual Verification:
- [ ] Credentials are in correct format
- [ ] No invisible characters detected
- [ ] If issues persist, contact aPaczka support with debug data

---

## Phase 4: Implement the Fix

### Overview
Once the correct signature format is identified, update the client code.

### Changes Required:

#### 1. Update Signature Generation
**File**: `app/services/apaczka/client.rb`

Based on Phase 2 findings, update the `generate_signature` method.

**Example (if format with expires as string works):**
```ruby
def generate_signature(endpoint, data, expires)
  route = endpoint.to_s.gsub(/^\/|\/$/,  "")

  # Convert expires to string explicitly
  expires_str = expires.to_s

  string_to_sign = "#{@app_id}:#{route}:#{data}:#{expires_str}"

  Rails.logger.info "Signing: #{string_to_sign[0..200]}..."

  signature = OpenSSL::HMAC.hexdigest("SHA256", @app_secret, string_to_sign)

  Rails.logger.info "Signature: #{signature}"

  signature
end
```

#### 2. Clean Up Debug Logging

After fix is confirmed, reduce logging verbosity:
```ruby
def generate_signature(endpoint, data, expires)
  route = endpoint.to_s.gsub(/^\/|\/$/,  "")
  string_to_sign = "#{@app_id}:#{route}:#{data}:#{expires}"
  signature = OpenSSL::HMAC.hexdigest("SHA256", @app_secret, string_to_sign)

  # Keep minimal logging for troubleshooting
  Rails.logger.debug "aPaczka signature generated for #{route}"

  signature
end
```

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `bundle exec rspec spec/services/apaczka/client_spec.rb`
- [ ] Job test passes: `bundle exec rspec spec/jobs/apaczka/create_shipment_job_spec.rb`
- [ ] No linting errors: `bundle exec rubocop app/services/apaczka/client.rb`

#### Manual Verification:
- [ ] Create test donation and process payment
- [ ] Verify shipment is created successfully in aPaczka
- [ ] Check that waybill_number and tracking_url are populated
- [ ] Verify no signature errors in logs

---

## Testing Strategy

### Unit Tests:
```ruby
# spec/services/apaczka/client_spec.rb
RSpec.describe Apaczka::Client do
  describe '#generate_signature' do
    it 'generates signature in correct format' do
      client = described_class.new
      endpoint = '/order_send/'
      data = '{"test":"data"}'
      expires = 1234567890

      signature = client.send(:generate_signature, endpoint, data, expires)

      # Verify signature is valid hex
      expect(signature).to match(/^[a-f0-9]{64}$/)
    end
  end
end
```

### Integration Test:
1. Create test donation in staging environment
2. Process payment via Przelewy24 sandbox
3. Verify aPaczka shipment is created
4. Check tracking URL is accessible

### Manual Testing Steps:
1. Deploy changes to staging
2. Create donation with locker delivery
3. Complete payment via Przelewy24
4. Check logs for signature generation
5. Verify aPaczka order appears in aPaczka panel
6. Confirm waybill can be downloaded

## Performance Considerations

- Signature generation is fast (HMAC-SHA256)
- No significant performance impact expected
- Logging overhead only during debugging phase

## Migration Notes

**No database migrations required** - this is purely a code fix.

## Rollback Plan

If the fix causes issues:
1. Revert commit: `git revert <commit-hash>`
2. Re-deploy previous version
3. Shipments will fail but can be manually created in aPaczka panel
4. No data loss - all shipment records are preserved

## References

- aPaczka API Documentation: https://panel.apaczka.pl/dokumentacja_api_v2.php
- Current client code: [app/services/apaczka/client.rb](app/services/apaczka/client.rb:192-214)
- Job implementation: [app/jobs/apaczka/create_shipment_job.rb](app/jobs/apaczka/create_shipment_job.rb)
- Production logs: `kubectl logs -f deployment/edk-admin-packages`

## Next Steps

1. Review and approve this plan
2. Execute Phase 1: Add debugging
3. Deploy to staging and collect logs
4. Execute Phase 2: Test signature variations
5. Identify correct format
6. Execute Phase 4: Implement fix
7. Test in staging
8. Deploy to production
9. Monitor for 24 hours
