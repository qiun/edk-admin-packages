module Public
  class WebhooksController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def przelewy24
      Rails.logger.info "Przelewy24 webhook received: #{webhook_params.to_json}"
      Rails.logger.info "Received signature: #{webhook_params[:sign]}"

      # Verify webhook signature
      client = przelewy24_client
      unless client.verify_notification_signature(webhook_params)
        Rails.logger.error "Przelewy24 webhook signature verification failed"
        Rails.logger.error "Received sign: #{webhook_params[:sign]}"
        render json: { status: "ERROR", message: "Invalid signature" }, status: :unauthorized
        return
      end

      # Find donation by sessionId (payment_id)
      donation = Donation.find_by(payment_id: webhook_params[:sessionId])
      unless donation
        Rails.logger.error "Donation not found for sessionId: #{webhook_params[:sessionId]}"
        render json: { status: "ERROR", message: "Donation not found" }, status: :not_found
        return
      end

      # Verify transaction with Przelewy24 API
      verification = client.verify_transaction(
        session_id: webhook_params[:sessionId],
        order_id: webhook_params[:orderId],
        amount: webhook_params[:amount],
        currency: webhook_params[:currency]
      )

      unless verification[:success]
        Rails.logger.error "Przelewy24 transaction verification failed: #{verification[:response]}"
        render json: { status: "ERROR", message: "Verification failed" }, status: :unprocessable_entity
        return
      end

      # Update donation status
      ActiveRecord::Base.transaction do
        donation.update!(
          payment_status: "paid",
          payment_transaction_id: webhook_params[:orderId]
        )

        # Create shipment if gift was requested
        if donation.want_gift? && donation.locker_code.present?
          create_shipment_for_donation(donation)
        end

        # Send confirmation email
        DonationMailer.confirmation(donation).deliver_later
      end

      Rails.logger.info "Przelewy24 payment confirmed for donation ##{donation.id}"
      render json: { status: "OK" }
    rescue StandardError => e
      Rails.logger.error "Przelewy24 webhook processing error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { status: "ERROR", message: "Processing failed" }, status: :internal_server_error
    end

    private

    def webhook_params
      params.permit(:merchantId, :posId, :sessionId, :amount, :originAmount, :currency, :orderId,
                    :methodId, :statement, :sign, :reasonCode, :testMode)
    end

    def przelewy24_client
      Przelewy24::Client.new(
        merchant_id: ENV.fetch("PRZELEWY24_MERCHANT_ID"),
        pos_id: ENV.fetch("PRZELEWY24_POS_ID"),
        api_key: ENV.fetch("PRZELEWY24_API_KEY"),
        crc_key: ENV.fetch("PRZELEWY24_CRC_KEY"),
        sandbox: ENV.fetch("PRZELEWY24_SANDBOX", Rails.env.development?.to_s) == "true"
      )
    end

    def create_shipment_for_donation(donation)
      # Create shipment order
      shipment = Shipment.create!(
        donation: donation,
        status: "pending"
      )

      # Queue shipment creation job
      Apaczka::CreateShipmentJob.perform_later(shipment)

      Rails.logger.info "Created shipment ##{shipment.id} and queued aPaczka job for donation ##{donation.id}"
    end
  end
end
