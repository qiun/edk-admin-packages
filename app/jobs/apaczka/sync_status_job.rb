module Apaczka
  class SyncStatusJob < ApplicationJob
    queue_as :low

    APACZKA_STATUS_MAP = {
      "NEW"              => "label_ready",
      "READY_TO_SEND"    => "label_ready",
      "READY_TO_PICKUP"  => "ready_for_pickup",
      "ADVISING"         => "label_ready",
      "POSTED"           => "picked_up",
      "ON_THE_WAY"       => "in_transit",
      "OUT_FOR_DELIVERY" => "in_transit",
      "DELIVERED"        => "delivered",
      "AVIZO"            => "in_transit",
      "OTHER"            => "returned",
      "RETURNED"         => "returned",
      "CANCELLED"        => "failed",
      "FAILED"           => "failed"
    }.freeze

    TRACKABLE_STATUSES = %w[label_ready picked_up in_transit ready_for_pickup].freeze

    def perform
      client = ::Apaczka::Client.new

      Shipment.where(status: TRACKABLE_STATUSES)
              .where.not(apaczka_order_id: nil)
              .find_each do |shipment|
        sync_shipment(client, shipment)
      rescue => e
        Rails.logger.error("Sync failed for shipment ##{shipment.id}: #{e.message}")
      end
    end

    private

    def sync_shipment(client, shipment)
      apaczka_status = client.get_order_status(shipment.apaczka_order_id)
      return unless apaczka_status.present?

      new_status = APACZKA_STATUS_MAP[apaczka_status.to_s.upcase] || shipment.status
      return if shipment.status == new_status

      Rails.logger.info "Shipment ##{shipment.id}: #{shipment.status} → #{new_status} (aPaczka: #{apaczka_status})"

      shipment.update!(status: new_status)

      case new_status
      when "delivered"
        shipment.update!(delivered_at: Time.current)
        sync_source_status(shipment, :delivered)
        ShipmentMailer.delivered(shipment).deliver_later
      when "picked_up", "in_transit", "ready_for_pickup"
        sync_source_status(shipment, :shipped)
      end
    end

    def sync_source_status(shipment, target_status)
      source = shipment.source
      return unless source.is_a?(Order)

      case target_status
      when :delivered
        source.update!(status: :delivered) unless source.delivered? || source.cancelled?
      when :shipped
        source.update!(status: :shipped) unless source.shipped? || source.delivered? || source.cancelled?
      end
    end
  end
end
