module Apaczka
  class CreateShipmentJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(order_id)
      order = Order.find(order_id)
      return unless order.confirmed?

      client = ::Apaczka::Client.new
      result = client.create_shipment(order)

      if result[:success]
        shipment = order.create_shipment!(
          apaczka_order_id: result[:order_id],
          waybill_number: result[:waybill_number],
          tracking_url: result[:tracking_url],
          status: "label_printed"
        )

        # Pobierz etykietę PDF
        label_pdf = client.get_waybill(result[:order_id])
        shipment.update!(label_pdf: label_pdf) if label_pdf

        # Aktualizuj magazyn - przenieś z reserved do shipped
        order.edition.inventory.ship(order.quantity, reference: order.id)

        # Zmień status zamówienia
        order.update!(status: :shipped)

        # Wyślij powiadomienie (gdy będzie mailer)
        # ShipmentMailer.shipped(shipment).deliver_later
      else
        # Loguj błąd
        Rails.logger.error("aPaczka shipment creation failed for order #{order.id}: #{result[:error]}")

        # Powiadom admina (gdy będzie mailer)
        # AdminMailer.shipment_failed(order, result[:error]).deliver_later

        raise StandardError, "aPaczka API error: #{result[:error]}"
      end
    end
  end
end
