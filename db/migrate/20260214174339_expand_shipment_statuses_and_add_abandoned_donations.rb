class ExpandShipmentStatusesAndAddAbandonedDonations < ActiveRecord::Migration[8.1]
  def up
    # === SHIPMENT STATUSES ===
    # Obecne: pending, shipped, delivered, failed
    # Nowe:   pending, label_ready, picked_up, in_transit, ready_for_pickup, delivered, returned, failed
    #
    # Kolumna status jest stringiem więc nie wymaga zmian schematu,
    # wystarczy migracja danych.

    # Wszystkie "shipped" → "label_ready"
    # Bo "shipped" oznaczało tylko "etykieta wygenerowana w aPaczka",
    # nie wiemy czy kurier odebrał, więc to jest "label_ready"
    execute <<~SQL
      UPDATE shipments SET status = 'label_ready' WHERE status = 'shipped'
    SQL

    # === ORDER ↔ SHIPMENT CONSISTENCY ===
    # Zamówienia "confirmed" z aktywną wysyłką → "shipped"
    execute <<~SQL
      UPDATE orders SET status = 'shipped'
      WHERE status = 'confirmed'
      AND id IN (
        SELECT order_id FROM shipments
        WHERE order_id IS NOT NULL
        AND status IN ('label_ready', 'picked_up', 'in_transit', 'ready_for_pickup')
      )
    SQL

    # Zamówienia "confirmed" z wysyłką delivered → "delivered"
    execute <<~SQL
      UPDATE orders SET status = 'delivered'
      WHERE status = 'confirmed'
      AND id IN (
        SELECT order_id FROM shipments
        WHERE order_id IS NOT NULL
        AND status = 'delivered'
      )
    SQL

    # === DONATION ABANDONED ===
    # Stare pending donations (> 24h) → abandoned
    execute <<~SQL
      UPDATE donations SET payment_status = 'abandoned'
      WHERE payment_status = 'pending'
      AND created_at < '#{24.hours.ago.utc.strftime('%Y-%m-%d %H:%M:%S')}'
    SQL
  end

  def down
    # Cofnij shipment statuses
    execute <<~SQL
      UPDATE shipments SET status = 'shipped'
      WHERE status IN ('label_ready', 'picked_up', 'in_transit', 'ready_for_pickup')
    SQL

    execute <<~SQL
      UPDATE shipments SET status = 'failed'
      WHERE status = 'returned'
    SQL

    # Cofnij abandoned → pending
    execute <<~SQL
      UPDATE donations SET payment_status = 'pending'
      WHERE payment_status = 'abandoned'
    SQL
  end
end
