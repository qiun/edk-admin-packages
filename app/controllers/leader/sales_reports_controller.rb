module Leader
  class SalesReportsController < Leader::BaseController
    def index
      @edition = current_edition
      @reports = current_user.sales_reports
                             .where(edition: @edition)
                             .order(reported_at: :desc)

      @total_sold = @reports.sum(:quantity_sold)
      @settlement = current_user.settlements.find_or_initialize_by(edition: @edition)
      @can_report_more = calculate_max_reportable > 0
    end

    def new
      @report = current_user.sales_reports.new(edition: current_edition)
      @max_quantity = calculate_max_reportable

      if @max_quantity <= 0
        redirect_to leader_sales_reports_path, alert: "Brak pakietów do raportowania. Najpierw złóż zamówienie i poczekaj na dostawę."
      end
    end

    def create
      @report = current_user.sales_reports.new(report_params)
      @report.edition = current_edition
      @report.reported_at = Time.current

      if @report.save
        # Recalculate settlement asynchronously
        Settlements::RecalculateJob.perform_later(current_user, current_edition)

        redirect_to leader_sales_reports_path, notice: "Raport sprzedaży został zapisany"
      else
        @max_quantity = calculate_max_reportable
        render :new, status: :unprocessable_entity
      end
    end

    private

    def report_params
      params.require(:sales_report).permit(:quantity_sold, :notes)
    end

    def calculate_max_reportable
      edition = current_edition
      orders = current_user.orders.for_edition(edition)
      reports = current_user.sales_reports.where(edition: edition)

      # Can only report sold packages from shipped orders
      shipped_quantity = orders.where(status: [:shipped, :delivered]).sum(:quantity)
      already_reported = reports.sum(:quantity_sold)

      shipped_quantity - already_reported
    end
  end
end
