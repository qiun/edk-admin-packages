module Apaczka
  class CreateShipmentJob < ApplicationJob
    queue_as :default

    # Only retry on transient network errors, not on aPaczka API validation errors
    retry_on Faraday::TimeoutError, Faraday::ConnectionFailed, wait: :polynomially_longer, attempts: 3

    def perform(shipment_or_id)
      # Handle both Shipment object and Shipment ID
      shipment = shipment_or_id.is_a?(Shipment) ? shipment_or_id : Shipment.find(shipment_or_id)

      # Get the source (Order or Donation)
      source = shipment.source
      return unless can_create_shipment?(source)

      client = ::Apaczka::Client.new
      result = client.create_shipment(source)

      if result[:success]
        # Update existing shipment with aPaczka data
        shipment.update!(
          apaczka_order_id: result[:order_id],
          waybill_number: result[:waybill_number],
          tracking_url: result[:tracking_url],
          status: "label_printed"
        )

        # Pobierz etykietę PDF
        label_pdf = client.get_waybill(result[:order_id])
        shipment.update!(label_pdf: label_pdf) if label_pdf

        # Aktualizuj magazyn - przenieś z reserved/allocated do shipped
        if source.is_a?(Order)
          source.edition.inventory.ship(source.quantity, reference: source)
          source.update!(status: :shipped)
        elsif source.is_a?(Donation)
          # For donations, inventory was already reserved during donation creation
          source.edition.inventory.ship(source.quantity, reference: source) if source.edition&.inventory
          # Shipment status is tracked in the Shipment record, not in Donation
        end

        # Wyślij powiadomienie o wysyłce
        Rails.logger.info "[CreateShipmentJob] Sending shipment notification email"
        ShipmentMailer.shipped(shipment).deliver_later
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
