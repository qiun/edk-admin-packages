class SimplifyShipmentStatuses < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE shipments SET status = 'shipped' WHERE status IN ('label_printed', 'in_transit');
    SQL
  end

  def down
    # Not reversible - we can't determine which records were label_printed vs in_transit
  end
end
