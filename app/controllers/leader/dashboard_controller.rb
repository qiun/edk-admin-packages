module Leader
  class DashboardController < Leader::BaseController
    def index
      @edition = current_edition
      @orders = current_user.orders.for_edition(@edition).includes(:shipment)
      @settlement = current_user.settlements.find_by(edition: @edition)

      @stats = {
        total_ordered: @orders.sum(:quantity),
        total_shipped: @orders.where(status: [:shipped, :delivered]).sum(:quantity),
        total_reported_sold: current_user.sales_reports.where(edition: @edition).sum(:quantity_sold),
        amount_due: @settlement&.amount_due || 0
      }

      @can_order = !current_user.ordering_locked_for?(@edition)
      @recent_orders = @orders.order(created_at: :desc).limit(5)
    end
  end
end
