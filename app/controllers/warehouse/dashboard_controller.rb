module Warehouse
  class DashboardController < Warehouse::BaseController
    def index
      @edition = current_edition

      @stats = {
        pending_orders: @edition ? Order.for_edition(@edition).pending.count : 0,
        confirmed_today: @edition ? Order.for_edition(@edition).where(status: :confirmed, updated_at: Date.current.all_day).count : 0,
        shipped_today: Shipment.where(shipped_at: Date.current.all_day).count,
        total_shipments: Shipment.count
      }

      @recent_orders = if @edition
        Order.for_edition(@edition)
             .includes(:user, :shipment)
             .where(status: [:pending, :confirmed])
             .order(created_at: :desc)
             .limit(10)
      else
        Order.none
      end

      @recent_donations = if @edition
        Donation.for_edition(@edition)
                .includes(:shipment)
                .where(payment_status: :paid)
                .order(created_at: :desc)
                .limit(10)
      else
        Donation.none
      end
    end
  end
end
