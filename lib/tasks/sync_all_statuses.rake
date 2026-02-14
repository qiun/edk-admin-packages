# frozen_string_literal: true

namespace :shipments do
  desc "One-time sync of all trackable shipment statuses from aPaczka API"
  task sync_all: :environment do
    client = Apaczka::Client.new

    trackable = Shipment.where.not(apaczka_order_id: nil)
                        .where(status: %w[label_ready picked_up in_transit ready_for_pickup])

    total = trackable.count
    puts "Found #{total} trackable shipments to sync..."

    synced = 0
    errors = 0

    trackable.find_each do |shipment|
      apaczka_status = client.get_order_status(shipment.apaczka_order_id)

      unless apaczka_status.present?
        puts "  [SKIP] Shipment ##{shipment.id} (aPaczka order #{shipment.apaczka_order_id}) - no status returned"
        errors += 1
        next
      end

      new_status = Apaczka::SyncStatusJob::APACZKA_STATUS_MAP[apaczka_status.to_s.upcase]

      unless new_status
        puts "  [SKIP] Shipment ##{shipment.id} - unknown aPaczka status: #{apaczka_status}"
        errors += 1
        next
      end

      if shipment.status == new_status
        puts "  [OK]   Shipment ##{shipment.id} - already #{new_status}"
        next
      end

      old_status = shipment.status
      shipment.update!(status: new_status)

      # Sync source (order/donation) status too
      if shipment.order.present?
        case new_status
        when "picked_up", "in_transit"
          shipment.order.update!(status: :shipped) unless shipment.order.status == "shipped"
        when "ready_for_pickup", "delivered"
          shipment.order.update!(status: :delivered) unless shipment.order.status == "delivered"
        when "returned"
          shipment.order.update!(status: :cancelled) unless shipment.order.status == "cancelled"
        end
      end

      puts "  [SYNC] Shipment ##{shipment.id}: #{old_status} -> #{new_status}"
      synced += 1
    rescue => e
      puts "  [ERR]  Shipment ##{shipment.id}: #{e.message}"
      errors += 1
    end

    puts "\nDone! Synced: #{synced}, Errors: #{errors}, Total: #{total}"
  end
end
