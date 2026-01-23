module Public
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!, raise: false

    def przelewy24
      Rails.logger.info "Przelewy24 webhook received: #{params.to_json}"

      # TODO: Implement Przelewy24 verification
      donation = Donation.find_by(payment_id: params[:sessionId])

      if donation
        donation.update!(
          payment_status: "paid",
          payment_transaction_id: params[:orderId]
        )

        # TODO: Create shipment if want_gift
        # TODO: Send confirmation email

        render json: { status: "OK" }
      else
        render json: { status: "ERROR", message: "Donation not found" }, status: :not_found
      end
    end
  end
end
