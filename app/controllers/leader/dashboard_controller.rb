module Leader
  class DashboardController < Leader::BaseController
    def index
      @edition = current_edition
      @orders = current_user.orders.for_edition(@edition).includes(:shipment)
      @settlement = current_user.settlements.find_by(edition: @edition)

      @stats = {
        total_ordered: @orders.sum(:quantity),
        total_shipped: @orders.where(status: [ :shipped, :delivered ]).sum(:quantity),
        total_reported_sold: current_user.sales_reports.where(edition: @edition).sum(:quantity_sold),
        amount_due: @settlement&.amount_due || 0
      }

      @can_order = !current_user.ordering_locked_for?(@edition)
      @recent_orders = @orders.order(created_at: :desc).limit(5)

      # Regional management stats
      region_ids = current_user.area_groups
                               .flat_map { |ag| ag.regions.for_edition(@edition).pluck(:id) }

      @regional_stats = {
        total_regions: region_ids.count,
        total_allocated: RegionAllocation.where(region_id: region_ids, edition: @edition)
                                         .sum(:allocated_quantity),
        total_sold: RegionAllocation.where(region_id: region_ids, edition: @edition)
                                    .sum(:sold_quantity),
        total_payments: RegionalPayment.where(region_id: region_ids, edition: @edition)
                                       .sum(:amount),
        pending_transfers: RegionTransfer.where(edition: @edition)
                                         .where("from_region_id IN (?) OR to_region_id IN (?)",
                                                region_ids, region_ids)
                                         .where(status: :pending)
                                         .count
      }

      @recent_regions = Region.where(id: region_ids)
                              .order(created_at: :desc)
                              .limit(5)
    end
  end
end
