module Apaczka
  class CreateShipmentJob < ApplicationJob
    queue_as :default

    # Only retry on transient network errors, not on aPaczka API validation errors
    retry_on Faraday::TimeoutError, Faraday::ConnectionFailed, wait: :polynomially_longer, attempts: 3

    def perform(shipment_or_id)
      # Handle both Shipment object and Shipment ID
      shipment = shipment_or_id.is_a?(Shipment) ? shipment_or_id : Shipment.find(shipment_or_id)

      Rails.logger.info "[CreateShipmentJob] Processing shipment ##{shipment.id}, current status: #{shipment.status}"

      # Get the source (Order or Donation)
      source = shipment.source
      return unless can_create_shipment?(source)

      Rails.logger.info "[CreateShipmentJob] Calling aPaczka API for shipment ##{shipment.id}"
      client = ::Apaczka::Client.new
      result = client.create_shipment(source)

      Rails.logger.info "[CreateShipmentJob] aPaczka result for shipment ##{shipment.id}: success=#{result[:success]}, order_id=#{result[:order_id]}, error=#{result[:error]}"

      if result[:success]
        Rails.logger.info "[CreateShipmentJob] Updating shipment ##{shipment.id} with aPaczka data"
        # Update existing shipment with aPaczka data
        shipment.update!(
          apaczka_order_id: result[:order_id],
          waybill_number: result[:waybill_number],
          tracking_url: result[:tracking_url],
          status: "label_ready"
        )
        Rails.logger.info "[CreateShipmentJob] Shipment ##{shipment.id} updated successfully - new status: #{shipment.reload.status}"

        # Pobierz etykietę PDF
        Rails.logger.info "[CreateShipmentJob] Fetching waybill PDF for order #{result[:order_id]}"
        label_pdf = client.get_waybill(result[:order_id])
        shipment.update!(label_pdf: label_pdf) if label_pdf
        Rails.logger.info "[CreateShipmentJob] Waybill PDF saved: #{label_pdf.present?}"

        # Zsynchronizuj status zamówienia
        if source.is_a?(Order) && (source.confirmed? || source.pending?)
          source.update!(status: :shipped)
        end

        # Wyślij powiadomienie o wysyłce
        Rails.logger.info "[CreateShipmentJob] Sending shipment notification email for shipment ##{shipment.id}"
        ShipmentMailer.shipped(shipment).deliver_later
        Rails.logger.info "[CreateShipmentJob] ✓ Successfully completed job for shipment ##{shipment.id}"
      else
        # Loguj błąd i powiadom admina
        source_type = source.class.name
        source_id = source.id
        Rails.logger.error("aPaczka shipment creation failed for #{source_type} #{source_id}: #{result[:error]}")

        # Update shipment status to failed
        shipment.update(status: "failed", apaczka_response: { error: result[:error] })

        raise StandardError, "aPaczka API error: #{result[:error]}"
      end
    end

    private

    def can_create_shipment?(source)
      case source
      when Order
        source.confirmed?
      when Donation
        source.payment_status == "paid"
      else
        false
      end
    end
  end
end
