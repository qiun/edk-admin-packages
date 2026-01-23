# Przelewy24 Payment Integration

## Overview

Custom Ruby implementation of Przelewy24 payment gateway integration for the EDK donation system. This implementation does not use any external gems and directly interfaces with the Przelewy24 REST API v1.

## Files

- `client.rb` - Main Przelewy24 API client with transaction creation, verification, and webhook signature validation

## Implementation Details

### Client Architecture

The `Przelewy24::Client` class provides three main operations:

1. **Transaction Registration** (`create_transaction`)
   - Creates a new payment transaction with Przelewy24
   - Returns payment token and redirect URL
   - Generates SHA384 signature for request authentication

2. **Transaction Verification** (`verify_transaction`)
   - Verifies payment completion via API call
   - Called after receiving webhook notification
   - Returns success status and API response

3. **Webhook Signature Verification** (`verify_notification_signature`)
   - Validates incoming webhook notifications
   - Prevents fraudulent payment confirmations
   - Uses SHA384 hash of JSON payload + CRC key

### Security Features

#### Double Verification Pattern
```ruby
# 1. First verification: Check webhook signature
unless client.verify_notification_signature(webhook_params)
  return render_unauthorized
end

# 2. Second verification: Call Przelewy24 API to confirm
verification = client.verify_transaction(...)
unless verification[:success]
  return render_error
end
```

This two-step process ensures:
- Webhook originated from Przelewy24 (signature check)
- Payment was actually completed (API verification)
- Protection against replay attacks and fraud

#### Signature Generation

All API requests use SHA384 signatures with JSON payload:

```ruby
# Registration signature format:
{
  "sessionId": "{SessionId}",
  "merchantId": {MerchantId},
  "amount": {Amount},
  "currency": "{Currency}",
  "crc": "{CRC_KEY}"
}

# Verification signature format:
{
  "sessionId": "{SessionId}",
  "orderId": {OrderId},
  "amount": {Amount},
  "currency": "{Currency}",
  "crc": "{CRC_KEY}"
}
```

The JSON is serialized and hashed with SHA384 to produce the signature.

### API Endpoints

#### Sandbox vs Production

```ruby
SANDBOX_URL = "https://sandbox.przelewy24.pl"
PRODUCTION_URL = "https://secure.przelewy24.pl"
```

Environment controlled via `PRZELEWY24_SANDBOX` ENV variable.

#### Transaction Registration

**Endpoint**: `POST /api/v1/transaction/register`

**Authentication**: Basic Auth (POS ID + API Key)

**Request Body**:
```json
{
  "merchantId": 276306,
  "posId": 276306,
  "sessionId": "DON-1234567890-abcd1234",
  "amount": 10000,
  "currency": "PLN",
  "description": "Cegiełka EDK 2025 - 10 pakiet(y)",
  "email": "donor@example.com",
  "country": "PL",
  "language": "pl",
  "urlReturn": "https://wspieram.edk.org.pl/cegielka/sukces",
  "urlStatus": "https://wspieram.edk.org.pl/webhooks/przelewy24",
  "sign": "sha384_signature_here"
}
```

**Response**:
```json
{
  "data": {
    "token": "XXXX-XXXX-XXXX-XXXX"
  }
}
```

**Redirect URL**: `https://secure.przelewy24.pl/trnRequest/{token}`

#### Transaction Verification

**Endpoint**: `POST /api/v1/transaction/verify`

**Authentication**: Basic Auth (POS ID + API Key)

**Request Body**:
```json
{
  "merchantId": 276306,
  "posId": 276306,
  "sessionId": "DON-1234567890-abcd1234",
  "amount": 10000,
  "currency": "PLN",
  "orderId": 987654,
  "sign": "sha384_signature_here"
}
```

**Response**:
```json
{
  "data": {
    "status": "success"
  }
}
```

### Configuration

All configuration via environment variables (not Rails credentials):

```ruby
Przelewy24::Client.new(
  merchant_id: ENV.fetch("PRZELEWY24_MERCHANT_ID"),
  pos_id: ENV.fetch("PRZELEWY24_POS_ID"),
  api_key: ENV.fetch("PRZELEWY24_API_KEY"),
  crc_key: ENV.fetch("PRZELEWY24_CRC_KEY"),
  sandbox: ENV.fetch("PRZELEWY24_SANDBOX", Rails.env.development?.to_s) == "true"
)
```

Required ENV variables:
- `PRZELEWY24_MERCHANT_ID` - Merchant identifier (276306)
- `PRZELEWY24_POS_ID` - Point of Sale identifier (276306)
- `PRZELEWY24_API_KEY` - API authentication key (secret)
- `PRZELEWY24_CRC_KEY` - Signature generation key (secret)
- `PRZELEWY24_SANDBOX` - "true" or "false" (defaults to Rails env)
- `PRZELEWY24_RETURN_URL` - User redirect after payment
- `PRZELEWY24_STATUS_URL` - Webhook notification URL

### Payment Flow

1. **User submits donation form** → `DonationsController#create`
   - Generate unique payment ID: `DON-{timestamp}-{random_hex}`
   - Create Donation record with `payment_status: "pending"`
   - Call `create_przelewy24_payment(donation)`
   - Redirect user to Przelewy24 payment page

2. **User completes payment on Przelewy24**
   - Przelewy24 redirects to `PRZELEWY24_RETURN_URL`
   - Sends webhook to `PRZELEWY24_STATUS_URL`

3. **Webhook received** → `WebhooksController#przelewy24`
   - Verify webhook signature
   - Find donation by `payment_id` (sessionId)
   - Verify transaction with Przelewy24 API
   - Update donation: `payment_status: "paid"`
   - Create shipment if gift requested
   - Queue `Apaczka::CreateShipmentJob`

### Error Handling

```ruby
begin
  payment_result = create_przelewy24_payment(@donation)
  redirect_to payment_result[:redirect_url]
rescue Przelewy24::Client::Error => e
  Rails.logger.error "Payment creation failed: #{e.message}"
  @donation.update_column(:payment_status, "failed")
  flash[:error] = "Nie udało się utworzyć płatności."
  render :new, status: :unprocessable_entity
end
```

All API errors are logged and surfaced to users with friendly error messages.

### Amount Handling

**Important**: Przelewy24 uses grosze (1/100 PLN), not złoty:

```ruby
# Convert złoty to grosze
amount: (params[:amount].to_f * 100).to_i

# Example:
# 100.00 PLN → 10000 groszy
# 15.50 PLN → 1550 groszy
```

### Session ID Format

Payment session IDs use format: `DON-{unix_timestamp}-{random_hex}`

```ruby
def generate_payment_id
  "DON-#{Time.current.to_i}-#{SecureRandom.hex(4)}"
end

# Example: DON-1737671234-a3f9d21c
```

This ensures:
- Uniqueness (timestamp + random component)
- Identifiable as donation payment (DON prefix)
- Sortable chronologically
- No collisions across requests

## Testing

### Sandbox Mode

Set `PRZELEWY24_SANDBOX=true` to use test environment:

```bash
PRZELEWY24_SANDBOX=true
PRZELEWY24_RETURN_URL=http://localhost:3000/cegielka/sukces
PRZELEWY24_STATUS_URL=http://localhost:3000/webhooks/przelewy24
```

### Test Cards

Przelewy24 sandbox accepts test card numbers (see official documentation).

### Webhook Testing

Use ngrok or similar to expose local server for webhook delivery:

```bash
ngrok http 3000
# Update PRZELEWY24_STATUS_URL to ngrok URL
```

## Production Deployment

1. **Get production credentials** from Przelewy24 panel
2. **Set environment variables** in Kubernetes secrets:
   ```yaml
   PRZELEWY24_CRC_KEY: base64_encoded_secret
   PRZELEWY24_API_KEY: base64_encoded_secret
   ```

3. **Configure public URLs** in ConfigMap:
   ```yaml
   PRZELEWY24_SANDBOX: "false"
   PRZELEWY24_RETURN_URL: "https://wspieram.edk.org.pl/cegielka/sukces"
   PRZELEWY24_STATUS_URL: "https://wspieram.edk.org.pl/webhooks/przelewy24"
   ```

4. **Register webhook URL** in Przelewy24 panel
5. **Test end-to-end** with small real payment

## Monitoring

Key metrics to monitor:

- Payment creation failures (logged as errors)
- Webhook signature verification failures
- API verification failures
- Payment completion rate
- Average time to webhook delivery

## References

- [Przelewy24 API Documentation](https://developers.przelewy24.pl/)
- [Transaction Registration](https://developers.przelewy24.pl/index.php?en#tag/Transaction-Service/paths/~1api~1v1~1transaction~1register/post)
- [Transaction Verification](https://developers.przelewy24.pl/index.php?en#tag/Transaction-Service/paths/~1api~1v1~1transaction~1verify/put)
- [Webhook Notifications](https://developers.przelewy24.pl/index.php?en#section/Notifications)

## Migration Notes

This implementation replaces the previous Node.js/Next.js integration that used `@ingameltd/node-przelewy24` library. The Ruby implementation:

- Uses identical API endpoints and authentication
- Maintains same merchant credentials (276306)
- Implements same security measures (signature verification)
- Uses same payment flow (register → redirect → webhook → verify)
- Compatible with existing Przelewy24 panel configuration
