module Apaczka
  class SyncStatusJob < ApplicationJob
    queue_as :low

    def perform
      client = ::Apaczka::Client.new

      Shipment.where(status: %w[label_printed shipped in_transit]).find_each do |shipment|
        begin
          apaczka_status = client.get_order_status(shipment.apaczka_order_id)
          next unless apaczka_status

          new_status = map_apaczka_status(apaczka_status)

          if shipment.status != new_status
            shipment.update!(status: new_status)

            if new_status == "delivered"
              shipment.update!(delivered_at: Time.current)

              # Update source status if it's an Order
              if shipment.source.is_a?(Order)
                shipment.source.update!(status: :delivered)
              end

              # Wyślij powiadomienie o dostawie
              ShipmentMailer.delivered(shipment).deliver_later
            end
          end
        rescue => e
          Rails.logger.error("Failed to sync status for shipment #{shipment.id}: #{e.message}")
        end
      end
    end

    private

    def map_apaczka_status(apaczka_status)
      case apaczka_status.to_s.upcase
      when "READY_TO_SHIP"
        "label_printed"
      when "PICKED_UP", "IN_TRANSIT"
        "in_transit"
      when "DELIVERED", "READY_TO_PICKUP"
        "delivered"
      when "RETURNED"
        "failed"
      else
        "shipped"
      end
    end
  end
end
