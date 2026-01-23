module Admin
  class DashboardController < Admin::BaseController
    def index
      @edition = current_edition
      @inventory = @edition&.inventory

      @stats = {
        total_leaders: User.leader.count,
        pending_orders: @edition ? Order.for_edition(@edition).pending.count : 0,
        shipped_today: Shipment.where(shipped_at: Date.current.all_day).count,
        pending_settlements: Settlement.pending.count
      }

      @recent_orders = if @edition
        Order.for_edition(@edition)
             .includes(:user, :shipment)
             .order(created_at: :desc)
             .limit(10)
      else
        Order.none
      end

      @leaders_summary = User.leader.includes(:orders, :settlements).map do |leader|
        orders = @edition ? leader.orders.for_edition(@edition) : Order.none
        {
          leader: leader,
          total_ordered: orders.sum(:quantity),
          total_shipped: orders.shipped.sum(:quantity),
          pending: orders.pending.sum(:quantity)
        }
      end
    end
  end
end
